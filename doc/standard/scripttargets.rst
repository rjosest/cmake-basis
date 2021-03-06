.. meta::
    :description: This article documents the build of script targets as implemented
                  by BASIS, a build system and software implementation standard.

=======================
Build of Script Targets
=======================

Unlike source files written in non-scripting languages such as C++ or Java,
source files written in scripting languages such as Python, Perl, or BASH
do not need to be compiled before their execution. They are interpreted
directly and hence do not need to be build (in case of Python, however,
they are as well compiled by the interpreter itself to improve speed).
On the other side, CMake provides a mechanism to replace CMake
variables in a source file by their respective values which are set in the
``CMakeLists.txt`` files (or an included CMake script file). As it is often
useful to introduce build specific information in a script file such as
the relative location of auxiliary executables or data files, the
:apidoc:`basis_add_executable()` and :apidoc:`basis_add_library()` commands
also provide a means of building script files. How these functions process
scripts during the build of the software is discussed next. Afterwards it is
described how the build of scripts can be configured.


.. _ScriptTargets:

Prerequisites and Build Steps
=============================

During the build of a script, the CMake variables as given by
``@VARIABLE_NAME@`` patterns are replaced by the value of the
corresponding CMake variable if defined, or by an empty string otherwise.
Similar to the configuration of source files written in C++ or MATLAB,
the names of the script files which shall be configured by BASIS during
the build step have to end with the ``.in`` suffix.
Otherwise, the script file is not modified by the BASIS build
commands and simply copied to the build tree or installation tree,
respectively. Opposed to configuring the source files already during
the configure step of CMake, as is the case for C++ and MATLAB source files,
script files are configured during the build step to allow for the used
CMake variables to be set differently depending on whether the script is
intended for use inside the build tree or the installation tree.
Moreover, certain properties of the script target can still be modified
after the :apidoc:`basis_add_executable()` or :apidoc:`basis_add_library()`
command, respectively, using the :apidoc:`basis_set_target_properties()` or
:apidoc:`basis_set_property()` command. Hence, the final values of these
variables are not known before the configuration of the build system has
been completed. Therefore, all CMake variables which are defined when the
:apidoc:`basis_add_executable()` or :apidoc:`basis_add_library()`
command is called, are dumped to a CMake script file to preserve their value
at this moment and the dump of the variables is written to a file in the
build tree. This file is loaded again during the build step by the custom
build command which eventually configures the script file using CMake's
`configure_file()`_ command with the ``@ONLY`` option. This build command
configures the script file twice. The first "built" script is intended for
use within the build tree while the second "built" script will be copied
upon installation to the installation tree.

Before each configuration of the (template) script file (the ``.in``
source file in the source tree), the file with the dumped CMake variable
values and the various script configuration files are included in the
following order:

1. Dump file of CMake variables defined when the script target was added.
2. Default script configuration file of BASIS (``BasisScriptConfig.cmake``).
3. Default script configuration file of individual project
   (``ScriptConfig.cmake``, optional).
4. Script configuration code specified using the ``CONFIG`` argument of the
   :apidoc:`basis_add_executable()` or :apidoc:`basis_add_library()` command.


.. _ScriptConfig:

Script Configuration
====================

The so-called script configuration is CMake code which defines CMake variables
for use within script files. This code is either saved in a CMake script file
with the ``.cmake`` file name extension or specified directly as argument
of the ``CONFIG`` option of the :apidoc:`basis_add_executable()` or
:apidoc:`basis_add_library()` command used to add a script target to the build
system. The variables defined by the script configuration are substituted by
their respective values during the build of the script target. Note that the
CMake code of the script configuration is evaluated during the build of the
script target, not during the configuration of the build system. During the
configuration of the build systems, the script configuration is, however,
configured in order to replace ``@VARIABLE_NAME@`` patterns in the configuration
by their respective values as defined by the build configuration
(``CMakeLists.txt`` files). Therefore, the variables defined in the script
configuration can be set differently for each of the two builds of the script
files. If the script configuration is evaluated before the configuration of
the script file for use inside the build tree, the CMake variable
``BUILD_INSTALL_SCRIPT`` is set to ``FALSE``. Otherwise, if the script
configuration is evaluated during the build of the script for use in the
installation tree, this variable is set to ``TRUE`` instead. It can therefore
be used to set the variables in the script configuration depending on whether
or not the script is build for use in the build tree or the installation tree.

For example, the project structure differs for the build tree and the
installation tree. Hence, relative file paths to the different directories
of data files, for instance, have to be set differently depending on the value
of ``BUILD_INSTALL_SCRIPT``, i.e.,

.. code-block:: cmake

    if (BUILD_INSTALL_SCRIPT)
      set (DATA_DIR "@CMAKE_INSTALL_PREFIX@/@INSTALL_DATA_DIR@")
    else ()
      set (DATA_DIR "@PROJECT_DATA_DIR@")
    endif ()

Avoid the use of absolute paths, however! Instead, use the ``__DIR__`` variable
which is set in the build script to the directory of the output script file
to make these paths relative to this directory which contains the configured
script file. These relative paths which are defined by the script configuration
are then used in the script file as follows:

.. code-block:: bash

    #! /usr/bin/env bash
    . ${BASIS_BASH_UTILITIES} || { echo "Failed to import BASIS utilities!" 1>&2; exit 1; }
    exedir EXEDIR && readonly EXEDIR
    [ $? -eq 0 ] || { echo 'Failed to determine directory of this executable!'; exit 1; }
    readonly DATA_DIR="${EXEDIR}/@DATA_DIR@"

where ``DATA_DIR`` is the relative path to the required data files as determined
during the evaluation of the script configuration. See documentation of
the :apidoc:`basis_set_script_path()` function for a convenience function which
can be  used therefore. Note that this function is defined in the custom build
script generated by BASIS for the build of each script target and hence can only be
used within a script configuration. For example, use this function as follows
in the ``PROJECT_CONFIG_DIR/ScriptConfig.cmake.in`` script configuration
file of your project:

.. code-block:: cmake

    basis_set_script_path(DATA_DIR "@PROJECT_DATA_DIR@" "@INSTALL_DATA_DIR@")

Note that most of the more common variables which are useful for the development
of scripts are already defined by the default script configuration file of BASIS.
Refer to the documentation of the :apidoc:`BasisScriptConfig.cmake` file for a
list of available variables.


.. _configure_file(): http://www.cmake.org/cmake/help/v2.8.8/cmake.html#command:configure_file
