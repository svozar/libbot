# Macros to simplify compliance with the pods build policies.
#
# Available macros:
#
# C/C++
#
#   pods_install_headers(...)
#   pods_install_libraries(...)
#   pods_install_executables(...)
#   pods_install_pkg_config_file(...)
#
#   pods_use_pkg_config_packages(...)
#
# Python:
#
#   pods_install_python_script(...)
#   pods_install_python_packages(...)
#
# Java:
#
#   TODO
#
# Other:
#
#   pods_config_search_paths()      Configures include, pkg-config, and linker paths.
#                                   Automatically invoked, do not invoke manually.
#
# ----
# File: pods.cmake
# Distributed with pods version: 10.09.30

# pods_install_headers(<header1.h> ... DESTINATION <subdir_name>)
# 
# Install a (list) of header files.
#
# Header files will all be installed to include/<subdir_name>
function(pods_install_headers)
    list(GET ARGV -2 checkword)
    if(NOT checkword STREQUAL DESTINATION)
        message(FATAL_ERROR "pods_install_headers missing DESTINATION parameter")
    endif()

    list(GET ARGV -1 dest_dir)
    list(REMOVE_AT ARGV -1)
    list(REMOVE_AT ARGV -1)

	install(FILES ${ARGV} DESTINATION include/${dest_dir})
endfunction(pods_install_headers)

# pods_install_executables(<executable1> ...)
#
# Install a (list) of executables to bin/
function(pods_install_executables)
    install(TARGETS ${ARGV} RUNTIME DESTINATION bin)
endfunction(pods_install_executables)

# pods_install_libraries(<library1> ...)
#
# Install a (list) of libraries to lib/
function(pods_install_libraries)
	install(TARGETS ${ARGV} LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
endfunction(pods_install_libraries)


# pods_install_pkg_config_file(<package-name> 
#                              [VERSION <version>]
#                              [DESCRIPTION <description>]
#                              [CFLAGS <cflag> ...]
#                              [LIBS <lflag> ...]
#                              [REQUIRES <required-package-name> ...])
# 
# Create and install a pkg-config .pc file.
#
# example:
#    add_library(mylib mylib.c)
#    pods_install_pkg_config_file(mylib LIBS -lmylib REQUIRES glib-2.0)
function(pods_install_pkg_config_file)
    list(GET ARGV 0 pc_name)
    # TODO error check

    set(pc_version 0.0.1)
    set(pc_description ${pc_name})
    set(pc_requires "")
    set(pc_libs "")
    set(pc_cflags "")
    set(pc_fname "${CMAKE_CURRENT_BINARY_DIR}/${pc_name}.pc")

    set(modewords LIBS CFLAGS REQUIRES VERSION DESCRIPTION)
    set(curmode "")

    # parse function arguments and populate pkg-config parameters
    list(REMOVE_AT ARGV 0)
    foreach(word ${ARGV})
        list(FIND modewords ${word} mode_index)
        if(${mode_index} GREATER -1)
            set(curmode ${word})
        elseif(curmode STREQUAL LIBS)
            set(pc_libs "${pc_libs} ${word}")
        elseif(curmode STREQUAL CFLAGS)
            set(pc_cflags "${pc_cflags} ${word}")
        elseif(curmode STREQUAL REQUIRES)
            set(pc_requires "${pc_requires} ${word}")
        elseif(curmode STREQUAL VERSION)
            set(pc_version ${word})
            set(curmode "")
        elseif(curmode STREQUAL DESCRIPTION)
            set(pc_description "${word}")
            set(curmode "")
        else(${mode_index} GREATER -1)
            message("WARNING incorrect use of pods_add_pkg_config (${word})")
            break()
        endif(${mode_index} GREATER -1)
    endforeach(word)

    # write the .pc file out
    file(WRITE ${pc_fname}
        "prefix=${CMAKE_INSTALL_PREFIX}\n"
        "exec_prefix=\${prefix}\n"
        "libdir=\${exec_prefix}/lib\n"
        "includedir=\${prefix}/include\n"
        "\n"
        "Name: ${pc_name}\n"
        "Description: ${pc_description}\n"
        "Requires: ${pc_requires}\n"
        "Version: ${pc_version}\n"
        "Libs: -L\${exec_prefix}/lib ${pc_libs}\n"
        "Cflags: ${pc_cflags}\n")

    # mark the .pc file for installation to the lib/pkgconfig directory
    install(FILES ${pc_fname} DESTINATION lib/pkgconfig)
endfunction(pods_install_pkg_config_file)


# pods_install_python_script(<script_name> <python_module>)
#
# Create and install a script that invokes the python interpreter with a
# specified module.
#
# A script will be installed to bin/<script_name>.  The script simply
# adds <install-prefix>/lib/pythonX.Y/site-packages to the python path, and
# then invokes `python -m <python_module>`.
function(pods_install_python_script script_name py_module)
    find_package(PythonInterp REQUIRED)

    # which python version?
    execute_process(COMMAND 
        ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(sys.version[:3])"
        OUTPUT_VARIABLE pyversion)

    # where do we install .py files to?
    set(python_install_dir 
        ${CMAKE_INSTALL_PREFIX}/lib/python${pyversion}/site-packages)

    # write the script file
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${script_name} "#!/bin/sh\n"
        "export PYTHONPATH=${python_install_dir}:\${PYTHONPATH}\n"
        "exec python -m ${py_module} $*\n")

    # install it...
    install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/${script_name} DESTINATION bin)
endfunction()

# pods_install_python_packages(<src_dir>)
#
# Install python packages to lib/pythonX.Y/site-packages, where X.Y refers to
# the current python version (e.g., 2.6)
#
# Recursively searches <src_dir> for .py files, byte-compiles them, and
# installs them
function(pods_install_python_packages py_src_dir)
    find_package(PythonInterp REQUIRED)

    # which python version?
    execute_process(COMMAND 
        ${PYTHON_EXECUTABLE} -c "import sys; sys.stdout.write(sys.version[:3])"
        OUTPUT_VARIABLE pyversion)

    # where do we install .py files to?
    set(python_install_dir 
        ${CMAKE_INSTALL_PREFIX}/lib/python${pyversion}/site-packages)

    if(ARGC GREATER 1)
        message(FATAL_ERROR "NYI")
    else()
        # get a list of all .py files
        file(GLOB_RECURSE py_files RELATIVE ${py_src_dir} ${py_src_dir}/*.py)

        # add rules for byte-compiling .py --> .pyc
        foreach(py_file ${py_files})
            get_filename_component(py_dirname ${py_file} PATH)
            add_custom_command(OUTPUT "${py_src_dir}/${py_file}c" 
                COMMAND ${PYTHON_EXECUTABLE} -m py_compile ${py_src_dir}/${py_file} 
                DEPENDS ${py_src_dir}/${py_file})
            list(APPEND pyc_files "${py_src_dir}/${py_file}c")

            # install python file and byte-compiled file
            install(FILES ${py_src_dir}/${py_file} ${py_src_dir}/${py_file}c
                DESTINATION "${python_install_dir}/${py_dirname}")
#            message("${py_src_dir}/${py_file} -> ${python_install_dir}/${py_dirname}")
        endforeach()
        string(REGEX REPLACE "[^a-zA-Z0-9]" "_" san_src_dir "${py_src_dir}")
        add_custom_target("pyc_${san_src_dir}" ALL DEPENDS ${pyc_files})
    endif()
endfunction()


# pods_use_pkg_config_packages(<target> <package-name> ...)
#
# Convenience macro to get compiler and linker flags from pkg-config and apply them
# to the specified target.
#
# Invokes `pkg-config --cflags-only-I <package-name> ...` and adds the result to the
# include directories.
#
# Additionally, invokes `pkg-config --libs <package-name> ...` and adds the result to
# the target's link flags (via target_link_libraries)
macro(pods_use_pkg_config_packages target)
    if(${ARGC} LESS 2)
        message(WARNING "Useless invocation of pods_use_pkg_config_packages")
        return()
    endif()
    find_package(PkgConfig REQUIRED)
    execute_process(COMMAND 
        ${PKG_CONFIG_EXECUTABLE} --cflags-only-I ${ARGN}
        OUTPUT_VARIABLE _pods_pkg_include_flags)
    string(STRIP ${_pods_pkg_include_flags} _pods_pkg_include_flags)
    string(REPLACE "-I" "" _pods_pkg_include_flags "${_pods_pkg_include_flags}")
	separate_arguments(_pods_pkg_include_flags)
    #    message("include: ${_pods_pkg_include_flags}")
    execute_process(COMMAND 
        ${PKG_CONFIG_EXECUTABLE} --libs ${ARGN}
        OUTPUT_VARIABLE _pods_pkg_ldflags)
    string(STRIP ${_pods_pkg_ldflags} _pods_pkg_ldflags)
    #    message("ldflags: ${_pods_pkg_ldflags}")
    include_directories(${_pods_pkg_include_flags})
    target_link_libraries(${target} ${_pods_pkg_ldflags})
    unset(_pods_pkg_include_flags)
    unset(_pods_pkg_ldflags)
endmacro()


# pods_config_search_paths()
#
# Setup include, linker, and pkg-config paths according to the pods core
# policy.  This macro is automatically invoked, there is no need to do so
# manually.
macro(pods_config_search_paths)
    if(NOT DEFINED __pods_setup)
        # add build/lib/pkgconfig to the pkg-config search path
        set(ENV{PKG_CONFIG_PATH} ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig)

        # add build/include to the compiler include path
        include_directories(${CMAKE_INSTALL_PREFIX}/include)

        # add build/lib to the link path
        link_directories(${CMAKE_INSTALL_PREFIX}/lib)

        # abuse RPATH
        set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/lib)

        set(__pods_setup true)
    endif(NOT DEFINED __pods_setup)
endmacro(pods_config_search_paths)

pods_config_search_paths()