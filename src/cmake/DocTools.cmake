##############################################################################
# @file  DocTools.cmake
# @brief Tools related to gnerating or adding software documentation.
#
# Copyright (c) 2011, 2012 University of Pennsylvania. All rights reserved.<br />
# See http://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
#
# @ingroup CMakeTools
##############################################################################

if (__BASIS_DOCTOOLS_INCLUDED)
  return ()
else ()
  set (__BASIS_DOCTOOLS_INCLUDED TRUE)
endif ()


# ============================================================================
# adding / generating documentation
# ============================================================================

# ----------------------------------------------------------------------------
## @brief Add documentation target.
#
# This function is used to add a software documentation files to the project
# which are either just copied to the installation or generated from input
# files such as in particular source code files and documentation files
# marked up using one of the supported lightweight markup languages.
#
# The supported generators are:
# <table border="0">
#   <tr>
#     @tp @b None @endtp
#     <td>This generator simply installs the given file or all files within
#         the specified directory.</td>
#   </tr>
#   <tr>
#     @tp @b Doxygen @endtp
#     <td>Used to generate API documentation from in-source code comments and
#         other related files marked up using Doxygen comments. See
#         basis_add_doxygen_doc() for more details.</td>
#   </tr>
#   <tr>
#     @tp @b Sphinx @endtp
#     <td>Used to generate documentation such as a web site from reStructuredText.
#         See basis_add_sphinx_doc() for more details.</td>
#   </tr>
# </table>
#
# @param [in] TARGET_NAME Name of the documentation target or file.
# @param [in] ARGN        Documentation generator as "GENERATOR generator" option
#                         and additional arguments for the particular generator.
#                         The case of the generator name is ignored, i.e.,
#                         @c Doxygen, @c DOXYGEN, @c doxYgen are all valid arguments
#                         which select the @c Doxygen generator. The default generator
#                         is the @c None generator.</td>
#
# @returns Adds a custom target @p TARGET_NAME for the generation of the
#          documentation.
#
# @sa basis_install_doc()
# @sa basis_add_doxygen_doc()
# @sa basis_add_sphinx_doc()
#
# @ingroup CMakeAPI
function (basis_add_doc TARGET_NAME)
  CMAKE_PARSE_ARGUMENTS (ARGN "" "GENERATOR" "" ${ARGN})
  if (NOT ARGN_GENERATOR)
    set (ARGN_GENERATOR "NONE")
  else ()
    string (TOUPPER "${ARGN_GENERATOR}" ARGN_GENERATOR)
  endif ()
  if (ARGN_GENERATOR MATCHES "NONE")
    basis_install_doc (${TARGET_NAME})
  elseif (ARGN_GENERATOR MATCHES "DOXYGEN")
    basis_add_doxygen_doc (${TARGET_NAME} ${ARGN_UNPARSED_ARGUMENTS})
  elseif (ARGN_GENERATOR MATCHES "SPHINX")
    basis_add_sphinx_doc (${TARGET_NAME} ${ARGN_UNPARSED_ARGUMENTS})
  else ()
    message (FATAL_ERROR "Unknown documentation generator: ${ARGN_GENERATOR}.")
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Install documentation file(s).
#
# This function either adds an installation rule for a single documentation
# file or a directory containing multiple documentation files.
#
# Example:
# @code
# basis_install_doc ("User Manual.pdf" OUTPUT_NAME "BASIS User Manual.pdf")
# basis_install_doc (DeveloperManual.docx COMPONENT dev)
# basis_install_doc (SourceManual.html    COMPONENT src)
# @endcode
#
# @param [in] SOURCE Documentation file or directory to install.
# @param [in] ARGN   List of optional arguments. Valid arguments are:
# @par
# <table border="0">
#   <tr>
#     @tp @b COMPONENT component @endtp
#     <td>Name of the component this documentation belongs to.
#         Defaults to @c BASIS_RUNTIME_COMPONENT.</td>
#   </tr>
#   <tr>
#     @tp @b DESTINATION dir @endtp
#     <td>Installation directory prefix. Defaults to @c INSTALL_DOC_DIR.</td>
#   </tr>
#   <tr>
#     @tp @b OUTPUT_NAME name @endtp
#     <td>Name of file or directory after installation.</td>
#   </tr>
# </table>
#
# @sa basis_add_doc()
function (basis_install_doc SOURCE)
  CMAKE_PARSE_ARGUMENTS (ARGN "" "COMPONENT;DESTINATION;OUTPUT_NAME" "" ${ARGN})

  if (NOT ARGN_DESTINATION)
    set (ARGN_DESTINATION "${INSTALL_DOC_DIR}")
  endif ()
  if (NOT ARGN_COMPONENT)
    set (ARGN_COMPONENT "${BASIS_RUNTIME_COMPONENT}")
  endif ()
  if (NOT ARGN_COMPONENT)
    set (ARGN_COMPONENT "Unspecified")
  endif ()
  if (NOT ARGN_OUTPUT_NAME)
    basis_get_filename_component (ARGN_OUTPUT_NAME "${SOURCE}" NAME)
  endif ()

  basis_get_relative_path (
    RELPATH
      "${CMAKE_SOURCE_DIR}"
      "${CMAKE_CURRENT_SOURCE_DIR}/${ARGN_OUTPUT_NAME}"
  )

  if (BASIS_VERBOSE)
    message (STATUS "Adding documentation ${RELPATH}...")
  endif ()

  if (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE}")
    basis_install_directory (
      "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE}"
      "${ARGN_DESTINATION}/${ARGN_OUTPUT_NAME}"
      COMPONENT "${ARGN_COMPONENT}"
    )
  else ()
    install (
      FILES       "${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE}"
      DESTINATION "${ARGN_DESTINATION}"
      COMPONENT   "${ARGN_COMPONENT}"
      RENAME      "${ARGN_OUTPUT_NAME}"
    )
  endif ()

  if (BASIS_VERBOSE)
    message (STATUS "Adding documentation ${RELPATH}... - done")
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add documentation to be generated by Doxygen.
#
# This function adds a build target to generate documentation from in-source
# code comments and other related project pages using
# <a href="http://www.stack.nl/~dimitri/doxygen/index.html">Doxygen</a>.
#
# @param [in] TARGET_NAME Name of the documentation target.
# @param [in] ARGN        List of arguments. The valid arguments are:
# @par
# <table border="0">
#   <tr>
#     @tp @b COMPONENT component @endtp
#     <td>Name of the component this documentation belongs to.
#         Defaults to @c BASIS_LIBRARY_COMPONENT.</td>
#   </tr>
#   <tr>
#     @tp @b DESTINATION dir @endtp
#     <td>Installation directory prefix. Defaults to
#         @c INSTALL_&ltTARGET&gt;_DIR in case of HTML output if set.
#         Otherwise, the generated HTML files are not installed.</td>
#   </tr>
#   <tr>
#     @tp @b DOXYFILE file @endtp
#     <td>Name of the template Doxyfile.</td>
#   </tr>
#   <tr>
#     @tp @b PROJECT_NAME name @endtp
#     <td>Value for Doxygen's @c PROJECT_NAME tag which is used to
#         specify the project name.@n
#         Default: @c PROJECT_NAME.</td>
#   </tr>
#   <tr>
#     @tp @b PROJECT_NUMBER version @endtp
#     <td>Value for Doxygen's @c PROJECT_NUMBER tag which is used
#         to specify the project version number.@n
#         Default: @c PROJECT_RELEASE.</td>
#   </tr>
#   <tr>
#     @tp @b INPUT path1 [path2 ...] @endtp
#     <td>Value for Doxygen's @c INPUT tag which is used to specify input
#         directories/files. Any given input path is added to the default
#         input paths.@n
#         Default: @c PROJECT_CODE_DIR, @c BINARY_CODE_DIR,
#                  @c PROJECT_INCLUDE_DIR, @c BINARY_INCLUDE_DIR.</td>
#   </tr>
#   <tr>
#     @tp @b INPUT_FILTER filter @endtp
#     <td>
#       Value for Doxygen's @c INPUT_FILTER tag which can be used to
#       specify a default filter for all input files.@n
#       Default: @c doxyfilter of BASIS.
#     </td>
#   </tr>
#   <tr>
#     @tp @b FILTER_PATTERNS pattern1 [pattern2...] @endtp
#     <td>Value for Doxygen's @c FILTER_PATTERNS tag which can be used to
#         specify filters on a per file pattern basis.@n
#         Default: None.</td>
#   </tr>
#   <tr>
#     @tp @b INCLUDE_PATH path1 [path2...] @endtp
#     <td>Doxygen's @c INCLUDE_PATH tag can be used to specify one or more
#         directories that contain include files that are not input files
#         but should be processed by the preprocessor. Any given directories
#         are appended to the default include path considered.
#         Default: Directories added by basis_include_directories().</td>
#   </tr>
#   <tr>
#     @tp @b EXCLUDE_PATTERNS pattern1 [pattern2 ...] @endtp
#     <td>Additional patterns used for Doxygen's @c EXCLUDE_PATTERNS tag
#         which can be used to specify files and/or directories that
#         should be excluded from the INPUT source files.@n
#         Default: No exclude patterns.</td>
#   </tr>
#   <tr>
#     @tp @b OUTPUT fmt @endtp
#     <td>Specify output formats in which to generate the documentation.
#         Currently, only @c html and @c xml are supported.</td>
#   </tr>
#   <tr>
#     @tp @b OUTPUT_DIRECTORY dir @endtp
#     <td>Value for Doxygen's @c OUTPUT_DIRECTORY tag which can be used to
#         specify the output directory. The output files are written to
#         subdirectories named "html", "latex", "rtf", and "man".@n
#         Default: <tt>CMAKE_CURRENT_BINARY_DIR/TARGET_NAME</tt>.</td>
#   </tr>
#   <tr>
#     @tp @b COLS_IN_ALPHA_INDEX n @endtp
#     <td>Number of columns in alphabetical index. Default: 3.</td>
#   </tr>
# </table>
# @n
# See <a href="http://www.stack.nl/~dimitri/doxygen/config.html">here</a> for a
# documentation of the Doxygen tags.
# @n@n
# Example:
# @code
# basis_add_doxygen_doc (
#   apidoc
#   DOXYFILE        "Doxyfile.in"
#   PROJECT_NAME    "${PROJECT_NAME}"
#   PROJECT_VERSION "${PROJECT_VERSION}"
#   COMPONENT       dev
# )
# @endcode
#
# @sa basis_add_doc()
function (basis_add_doxygen_doc TARGET_NAME)
  # check target name
  basis_check_target_name ("${TARGET_NAME}")
  basis_make_target_uid (TARGET_UID "${TARGET_NAME}")
  string (TOLOWER "${TARGET_NAME}" TARGET_NAME_LOWER)
  string (TOUPPER "${TARGET_NAME}" TARGET_NAME_UPPER)
  # verbose output
  if (BASIS_VERBOSE)
    message (STATUS "Adding documentation ${TARGET_UID}...")
  endif ()
  # find Doxygen
  find_package (Doxygen QUIET)
  if (NOT DOXYGEN_EXECUTABLE)
    if (BUILD_DOCUMENTATION)
      message (FATAL_ERROR "Doxygen not found! Either install Doxygen and/or set DOXYGEN_EXECUTABLE or disable BUILD_DOCUMENTATION.")
    endif ()
    message (STATUS "Doxygen not found. Generation of ${TARGET_UID} documentation disabled.")
    if (BASIS_VERBOSE)
      message (STATUS "Adding documentation ${TARGET_UID}... - skipped")
    endif ()
    return ()
  endif ()
  # parse arguments
  CMAKE_PARSE_ARGUMENTS (
    DOXYGEN
      ""
      "COMPONENT;DESTINATION;DOXYFILE;TAGFILE;PROJECT_NAME;PROJECT_NUMBER;OUTPUT_DIRECTORY;COLS_IN_ALPHA_INDEX;MAN_SECTION"
      "INPUT;OUTPUT;INPUT_FILTER;FILTER_PATTERNS;EXCLUDE_PATTERNS;INCLUDE_PATH"
      ${ARGN_UNPARSED_ARGUMENTS}
  )
  # default component
  if (NOT DOXYGEN_COMPONENT)
    set (DOXYGEN_COMPONENT "${BASIS_LIBRARY_COMPONENT}")
  endif ()
  if (NOT DOXYGEN_COMPONENT)
    set (DOXYGEN_COMPONENT "Unspecified")
  endif ()
  # configuration file
  if (NOT DOXYGEN_DOXYFILE)
    set (DOXYGEN_DOXYFILE "${BASIS_DOXYGEN_DOXYFILE}")
  endif ()
  if (NOT EXISTS "${DOXYGEN_DOXYFILE}")
    message (FATAL_ERROR "Missing option DOXYGEN_FILE or Doxyfile ${DOXYGEN_DOXYFILE} does not exist.")
  endif ()
  # project name
  if (NOT DOXYGEN_PROJECT_NAME)
    set (DOXYGEN_PROJECT_NAME "${PROJECT_NAME}")
  endif ()
  if (NOT DOXYGEN_PROJECT_NUMBER)
    set (DOXYGEN_PROJECT_NUMBER "${PROJECT_RELEASE}")
  endif ()
  # standard input files
  list (APPEND DOXYGEN_INPUT "${PROJECT_SOURCE_DIR}/BasisProject.cmake")
  if (EXISTS "${PROJECT_CONFIG_DIR}/Depends.cmake")
    list (APPEND DOXYGEN_INPUT "${PROJECT_CONFIG_DIR}/Depends.cmake")
  endif ()
  if (EXISTS "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Directories.cmake")
    list (APPEND DOXYGEN_INPUT "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Directories.cmake")
  endif ()
  if (EXISTS "${BINARY_CONFIG_DIR}/BasisSettings.cmake")
    list (APPEND DOXYGEN_INPUT "${BINARY_CONFIG_DIR}/BasisSettings.cmake")
  endif ()
  if (EXISTS "${BINARY_CONFIG_DIR}/ProjectSettings.cmake")
    list (APPEND DOXYGEN_INPUT "${BINARY_CONFIG_DIR}/ProjectSettings.cmake")
  endif ()
  if (EXISTS "${BINARY_CONFIG_DIR}/Settings.cmake")
    list (APPEND DOXYGEN_INPUT "${BINARY_CONFIG_DIR}/Settings.cmake")
  elseif (EXISTS "${PROJECT_CONFIG_DIR}/Settings.cmake")
    list (APPEND DOXYGEN_INPUT "${PROJECT_CONFIG_DIR}/Settings.cmake")
  endif ()
  if (EXISTS "${BINARY_CONFIG_DIR}/BasisScriptConfig.cmake")
    list (APPEND DOXYGEN_INPUT "${BINARY_CONFIG_DIR}/BasisScriptConfig.cmake")
  endif ()
  if (EXISTS "${BINARY_CONFIG_DIR}/ScriptConfig.cmake")
    list (APPEND DOXYGEN_INPUT "${BINARY_CONFIG_DIR}/ScriptConfig.cmake")
  endif ()
  if (EXISTS "${PROJECT_CONFIG_DIR}/ConfigSettings.cmake")
    list (APPEND DOXYGEN_INPUT "${PROJECT_CONFIG_DIR}/ConfigSettings.cmake")
  endif ()
  if (EXISTS "${PROJECT_SOURCE_DIR}/CTestConfig.cmake")
    list (APPEND DOXYGEN_INPUT "${PROJECT_SOURCE_DIR}/CTestConfig.cmake")
  endif ()
  if (EXISTS "${PROJECT_BINARY_DIR}/CTestCustom.cmake")
    list (APPEND DOXYGEN_INPUT "${PROJECT_BINARY_DIR}/CTestCustom.cmake")
  endif ()
  # package configuration files - only exist *after* this function executed
  list (APPEND DOXYGEN_INPUT "${BINARY_CONFIG_DIR}/${PROJECT_NAME}Config.cmake")
  list (APPEND DOXYGEN_INPUT "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
  list (APPEND DOXYGEN_INPUT "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Use.cmake")
  # input directories
  if (NOT BASIS_AUTO_PREFIX_INCLUDES AND EXISTS "${PROJECT_INCLUDE_DIR}")
    list (APPEND DOXYGEN_INPUT "${PROJECT_INCLUDE_DIR}")
  endif ()
  if (EXISTS "${BINARY_INCLUDE_DIR}")
    list (APPEND DOXYGEN_INPUT "${BINARY_INCLUDE_DIR}")
  endif ()
  if (EXISTS "${BINARY_CODE_DIR}")
    list (APPEND DOXYGEN_INPUT "${BINARY_CODE_DIR}")
  endif ()
  if (EXISTS "${PROJECT_CODE_DIR}")
    list (APPEND DOXYGEN_INPUT "${PROJECT_CODE_DIR}")
  endif ()
  basis_get_relative_path (INCLUDE_DIR "${PROJECT_SOURCE_DIR}" "${PROJECT_INCLUDE_DIR}")
  basis_get_relative_path (CODE_DIR    "${PROJECT_SOURCE_DIR}" "${PROJECT_CODE_DIR}")
  foreach (M IN LISTS PROJECT_MODULES_ENABLED)
    if (EXISTS "${PROJECT_MODULES_DIR}/${M}/${CODE_DIR}")
      list (APPEND DOXYGEN_INPUT "${PROJECT_MODULES_DIR}/${M}/${CODE_DIR}")
    endif ()
    if (EXISTS "${PROJECT_MODULES_DIR}/${M}/${INCLUDE_DIR}")
      list (APPEND DOXYGEN_INPUT "${BINARY_MODULES_DIR}/${M}/${INCLUDE_DIR}")
    endif ()
  endforeach ()
  # add .dox files as input
  file (GLOB_RECURSE DOX_FILES "${PROJECT_DOC_DIR}/*.dox")
  list (SORT DOX_FILES) # alphabetic order
  list (APPEND DOXYGEN_INPUT ${DOX_FILES})
  # add .dox files of BASIS modules
  if (PROJECT_NAME MATCHES "^BASIS$")
    set (FilesystemHierarchyStandardPageRef "@ref FilesystemHierarchyStandard")
    set (BuildOfScriptTargetsPageRef        "@ref BuildOfScriptTargets")
  else ()
    set (FilesystemHierarchyStandardPageRef "Filesystem Hierarchy Standard")
    set (BuildOfScriptTargetsPageRef        "build of script targets")
  endif ()
  configure_file(
    "${BASIS_MODULE_PATH}/Modules.dox.in"
    "${CMAKE_CURRENT_BINARY_DIR}/BasisModules.dox" @ONLY)
  list (APPEND DOXYGEN_INPUT "${CMAKE_CURRENT_BINARY_DIR}/BasisModules.dox")
  # add .dox files of used BASIS utilities
  list (APPEND DOXYGEN_INPUT "${BASIS_MODULE_PATH}/Utilities.dox")
  list (APPEND DOXYGEN_INPUT "${BASIS_MODULE_PATH}/CxxUtilities.dox")
  foreach (L IN ITEMS Cxx Java Python Perl Bash Matlab)
    string (TOUPPER "${L}" U)
    if (U MATCHES "CXX")
      if (BASIS_UTILITIES_ENABLED MATCHES "CXX")
        set (PROJECT_USES_CXX_UTILITIES TRUE)
      else ()
        set (PROJECT_USES_CXX_UTILITIES FALSE)
      endif ()
    else ()
      basis_get_project_property (USES_${U}_UTILITIES PROPERTY PROJECT_USES_${U}_UTILITIES)
    endif ()
    if (USES_${U}_UTILITIES)
      list (FIND DOXYGEN_INPUT "${BASIS_MODULE_PATH}/Utilities.dox" IDX)
      if (IDX EQUAL -1)
        list (APPEND DOXYGEN_INPUT "${BASIS_MODULE_PATH}/Utilities.dox")
      endif ()
      list (APPEND DOXYGEN_INPUT "${BASIS_MODULE_PATH}/${L}Utilities.dox")
    endif ()
  endforeach ()
  # include path
  basis_get_project_property (INCLUDE_DIRS PROPERTY PROJECT_INCLUDE_DIRS)
  foreach (D IN LISTS INCLUDE_DIRS)
    list (FIND DOXYGEN_INPUT "${D}" IDX)
    if (IDX EQUAL -1)
      list (APPEND DOXYGEN_INCLUDE_PATH "${D}")
    endif ()
  endforeach ()
  basis_list_to_delimited_string (
    DOXYGEN_INCLUDE_PATH "\"\nINCLUDE_PATH          += \"" ${DOXYGEN_INCLUDE_PATH}
  )
  set (DOXYGEN_INCLUDE_PATH "\"${DOXYGEN_INCLUDE_PATH}\"")
  # make string from DOXYGEN_INPUT - after include path was set
  basis_list_to_delimited_string (
    DOXYGEN_INPUT "\"\nINPUT                 += \"" ${DOXYGEN_INPUT}
  )
  set (DOXYGEN_INPUT "\"${DOXYGEN_INPUT}\"")
  # input filters
  if (NOT DOXYGEN_INPUT_FILTER)
    basis_get_target_uid (DOXYFILTER "${BASIS_NAMESPACE_LOWER}.basis.doxyfilter")
    if (TARGET "${DOXYFILTER}")
      basis_get_target_location (DOXYGEN_INPUT_FILTER "${DOXYFILTER}" ABSOLUTE)
    endif ()
  else ()
    set (DOXYFILTER)
  endif ()
  if (DOXYGEN_INPUT_FILTER)
    if (WIN32)
      # Doxygen on Windows (XP, 32-bit) (at least up to version 1.8.0) seems
      # to have a problem of not calling filters which have a space character
      # in their file path correctly. The doxyfilter.bat Batch program is used
      # as a wrapper for the actual filter which is part of the BASIS build.
      # As this file is in the working directory of Doxygen, it can be
      # referenced relative to this working directory, i.e., without file paths.
      # The Batch program itself then calls the actual Doxygen filter with proper
      # quotes to ensure that spaces in the file path are handled correctly.
      # The file extension .bat shall distinguish this wrapper script from the actual
      # doxyfilter.cmd which is generated by BASIS on Windows.
      configure_file ("${BASIS_MODULE_PATH}/doxyfilter.bat.in" "doxyfilter.bat" @ONLY)
      set (DOXYGEN_INPUT_FILTER "doxyfilter.bat")
    endif ()
  endif ()
  basis_list_to_delimited_string (
    DOXYGEN_FILTER_PATTERNS "\"\nFILTER_PATTERNS       += \"" ${DOXYGEN_FILTER_PATTERNS}
  )
  if (DOXYGEN_FILTER_PATTERNS)
    set (DOXYGEN_FILTER_PATTERNS "\"${DOXYGEN_FILTER_PATTERNS}\"")
  endif ()
  # exclude patterns
  list (APPEND DOXYGEN_EXCLUDE_PATTERNS "cmake_install.cmake")
  list (APPEND DOXYGEN_EXCLUDE_PATTERNS "CTestTestfile.cmake")
  basis_list_to_delimited_string (
    DOXYGEN_EXCLUDE_PATTERNS "\"\nEXCLUDE_PATTERNS      += \"" ${DOXYGEN_EXCLUDE_PATTERNS}
  )
  set (DOXYGEN_EXCLUDE_PATTERNS "\"${DOXYGEN_EXCLUDE_PATTERNS}\"")
  # section for man pages
  if (NOT DOXYGEN_MAN_SECTION)
    set (DOXYGEN_MAN_SECTION 3)
  endif ()
  # outputs
  if (NOT DOXYGEN_OUTPUT_DIRECTORY)
    set (DOXYGEN_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME_LOWER}")
  endif ()
  if (DOXYGEN_TAGFILE MATCHES "^(None|NONE|none)$")
    set (DOXYGEN_TAGFILE)
  else ()
    set (DOXYGEN_TAGFILE "${DOXYGEN_OUTPUT_DIRECTORY}/Doxytags.${TARGET_NAME_LOWER}")
  endif ()
  if (NOT DOXYGEN_OUTPUT)
    set (DOXYGEN_OUTPUT html)
  endif ()
  foreach (F IN ITEMS HTML XML RTF LATEX MAN)
    set (DOXYGEN_GENERATE_${F} NO)
  endforeach ()
  foreach (f IN LISTS DOXYGEN_OUTPUT)
    if (NOT f MATCHES "^(html|xml)$")
      message (FATAL_ERROR "Invalid/Unsupported Doxygen output format: ${f}")
    endif ()
    string (TOUPPER "${f}" F)
    set (DOXYGEN_GENERATE_${F} YES)  # enable generation of this output
    set (DOXYGEN_${F}_OUTPUT "${f}") # relative output directory
  endforeach ()
  # other settings
  if (NOT DOXYGEN_COLS_IN_ALPHA_INDEX OR DOXYGEN_COLS_IN_ALPHA_INDEX MATCHES "[^0-9]")
    set (DOXYGEN_COLS_IN_ALPHA_INDEX 3)
  endif ()
  # HTML style
  set (DOXYGEN_HTML_STYLESHEET "${BASIS_MODULE_PATH}/doxygen_sbia.css")
  set (DOXYGEN_HTML_HEADER     "${BASIS_MODULE_PATH}/doxygen_header.html")
  set (DOXYGEN_HTML_FOOTER     "${BASIS_MODULE_PATH}/doxygen_footer.html")
  # click & jump in emacs and Visual Studio
  if (CMAKE_BUILD_TOOL MATCHES "(msdev|devenv)")
    set (DOXYGEN_WARN_FORMAT "\"$file($line) : $text \"")
  else ()
    set (DOXYGEN_WARN_FORMAT "\"$file:$line: $text \"")
  endif ()
  # installation directories
  set (INSTALL_${TARGET_NAME_UPPER}_DIR "" CACHE PATH "Installation directory for ${TARGET_NAME_UPPER}.")
  mark_as_advanced (INSTALL_${TARGET_NAME_UPPER}_DIR)
  foreach (f IN LISTS DOXYGEN_OUTPUT)
    string (TOUPPER "${f}" F)
    if (NOT DOXYGEN_${F}_DESTINATION)
      if (DOXYGEN_DESTINATION)
        set (DOXYGEN_${F}_DESTINATION "${DOXYGEN_DESTINATION}") # common destination
      elseif (INSTALL_${TARGET_NAME_UPPER}_DIR)
        set (DOXYGEN_${F}_DESTINATION "${INSTALL_${TARGET_NAME_UPPER}_DIR}") # global setting
      elseif (f MATCHES "man")
        if (INSTALL_MAN_DIR)
          set (DOXYGEN_${F}_DESTINATION "${INSTALL_MAN_DIR}/man${DOXYGEN_MAN_SECTION}") # default for manual pages
        endif ()
      elseif (NOT f MATCHES "html") # do not install excludes by default
        set (DOXYGEN_${F}_DESTINATION "${INSTALL_DOC_DIR}") # default destination
      endif ()
    endif ()
  endforeach ()
  # configure Doxyfile
  set (DOXYFILE "${DOXYGEN_OUTPUT_DIRECTORY}/Doxyfile.${TARGET_NAME_LOWER}")
  configure_file ("${DOXYGEN_DOXYFILE}" "${DOXYFILE}" @ONLY)
  # add target
  set (LOGOS)
  if (DOXYGEN_GENERATE_HTML)
    set (LOGOS "${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_HTML_OUTPUT}/logo_sbia.png"
               "${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_HTML_OUTPUT}/logo_penn.png")
    add_custom_command (
      OUTPUT   ${LOGOS}
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "${BASIS_MODULE_PATH}/logo_sbia.png"
                "${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_HTML_OUTPUT}/logo_sbia.png"
      COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "${BASIS_MODULE_PATH}/logo_penn.gif"
                "${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_HTML_OUTPUT}/logo_penn.gif"
      COMMENT "Copying logos to ${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_HTML_OUTPUT}/..."
    )
  endif ()
  set (OPTALL)
  if (BUILD_DOCUMENTATION AND BASIS_ALL_DOC)
    set (OPTALL "ALL")
  endif ()
  file (MAKE_DIRECTORY "${DOXYGEN_OUTPUT_DIRECTORY}")
  add_custom_target (
    ${TARGET_UID} ${OPTALL} "${DOXYGEN_EXECUTABLE}" "${DOXYFILE}"
    DEPENDS ${LOGOS}
    WORKING_DIRECTORY "${DOXYGEN_OUTPUT_DIRECTORY}"
    COMMENT "Building documentation ${TARGET_UID}..."
  )
  # memorize certain settings which might be useful to know by other functions
  # in particular, in case of the use of the XML output by other documentation
  # build tools such as Sphinx, the function that wants to make use of this
  # output can check if the Doxygen target has been configured properly and
  # further requires to know the location of the XML output
  set_target_properties (
    ${TARGET_UID}
    PROPERTIES
      BASIS_TYPE       Doxygen
      OUTPUT_DIRECTORY "${DOXYGEN_OUTPUT_DIRECTORY}"
      DOXYFILE         "${DOXYGEN_DOXYFILE}"
      TAGFILE          "${DOXYGEN_TAGFILE}"
      OUTPUT           "${DOXYGEN_OUTPUT}"
  )
  foreach (f IN LISTS DOXYGEN_OUTPUT)
    string (TOUPPER "${f}" F)
    set_target_properties (
      ${TARGET_UID}
      PROPERTIES
        ${F}_INSTALL_DIRECTORY "${DOXYGEN_${F}_DESTINATION}"
        ${F}_OUTPUT_DIRECTORY  "${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_${F}_OUTPUT}"
    )
    set_property (
      DIRECTORY
      APPEND PROPERTY
        ADDITIONAL_MAKE_CLEAN_FILES
          "${DOXYGEN_OUTPUT_DIRECTORY}/${DOXYGEN_${F}_OUTPUT}"
    )
  endforeach ()
  if (DOXYGEN_TAGFILE)
    set_property (
      DIRECTORY
      APPEND PROPERTY
        ADDITIONAL_MAKE_CLEAN_FILES
          "${DOXYGEN_TAGFILE}"
    )
  endif ()
  # The Doxygen filter, if a build target of this project, has to be build
  # before the documentation can be generated.
  if (TARGET "${DOXYFILTER}")
    add_dependencies (${TARGET_UID} ${DOXYFILTER})
  endif ()
  # The public header files shall be configured/copied before.
  if (TARGET headers)
    add_dependencies (${TARGET_UID} headers)
  endif ()
  # The documentation shall be build after all other executable and library
  # targets have been build. For example, a .py.in script file shall first
  # be "build", i.e., configured before the documentation is being generated
  # from the configured .py file.
  basis_get_project_property (TARGETS PROPERTY TARGETS)
  foreach (_UID ${TARGETS})
    get_target_property (BASIS_TYPE ${_UID} "BASIS_TYPE")
    if (BASIS_TYPE MATCHES "SCRIPT|EXECUTABLE|LIBRARY")
      add_dependencies (${TARGET_UID} ${_UID})
    endif ()
  endforeach ()
  # add general "doc" target
  if (NOT TARGET doc)
    add_custom_target (doc)
  endif ()
  add_dependencies (doc ${TARGET_UID})
  # install documentation
  install (
    CODE
      "
      set (HTML_DESTINATION \"${DOXYGEN_HTML_DESTINATION}\")
      set (MAN_DESTINATION  \"${DOXYGEN_MAN_DESTINATION}\")

      function (install_doxydoc FMT)
        string (TOUPPER \"\${FMT}\" FMT_UPPER)
        set (INSTALL_PREFIX \"\${\${FMT_UPPER}_DESTINATION}\")
        if (NOT INSTALL_PREFIX)
          return ()
        elseif (NOT IS_ABSOLUTE \"\${INSTALL_PREFIX}\")
          set (INSTALL_PREFIX \"${INSTALL_PREFIX}/\${INSTALL_PREFIX}\")
        endif ()
        set (EXT)
        set (DIR \"\${FMT}\")
        if (FMT MATCHES \".pdf\")
          set (EXT \".pdf\")
          set (DIR \"latex\")
        elseif (FMT MATCHES \".rtf\")
          set (EXT \".rtf\")
        elseif (FMT MATCHES \"man\")
          set (EXT \".?\")
        endif ()
        file (
          GLOB_RECURSE
            FILES
          RELATIVE \"${DOXYGEN_OUTPUT_DIRECTORY}/\${DIR}\"
            \"${DOXYGEN_OUTPUT_DIRECTORY}/\${DIR}/*\${EXT}\"
        )
        foreach (F IN LISTS FILES)
          execute_process (
            COMMAND \"${CMAKE_COMMAND}\" -E compare_files
                \"${DOXYGEN_OUTPUT_DIRECTORY}/\${DIR}/\${F}\"
                \"\${INSTALL_PREFIX}/\${F}\"
            RESULT_VARIABLE RC
            OUTPUT_QUIET
            ERROR_QUIET
          )
          if (RC EQUAL 0)
            message (STATUS \"Up-to-date: \${INSTALL_PREFIX}/\${F}\")
          else ()
            message (STATUS \"Installing: \${INSTALL_PREFIX}/\${F}\")
            execute_process (
              COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different
                  \"${DOXYGEN_OUTPUT_DIRECTORY}/\${DIR}/\${F}\"
                  \"\${INSTALL_PREFIX}/\${F}\"
              RESULT_VARIABLE RC
              OUTPUT_QUIET
              ERROR_QUIET
            )
            if (RC EQUAL 0)
              list (APPEND CMAKE_INSTALL_MANIFEST_FILES \"\${INSTALL_PREFIX}/\${F}\")
            else ()
              message (STATUS \"Failed to install \${INSTALL_PREFIX}/\${F}\")
            endif ()
          endif ()
        endforeach ()
        if (FMT MATCHES \"html\" AND EXISTS \"${DOXYGEN_TAGFILE}\")
          get_filename_component (DOXYGEN_TAGFILE_NAME \"${DOXYGEN_TAGFILE}\" NAME)
          execute_process (
            COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different
              \"${DOXYGEN_TAGFILE}\"
              \"\${INSTALL_PREFIX}/\${DOXYGEN_TAGFILE_NAME}\"
          )
          list (APPEND CMAKE_INSTALL_MANIFEST_FILES \"\${INSTALL_PREFIX}/\${DOXYGEN_TAGFILE_NAME}\")
        endif ()
      endfunction ()

      foreach (FMT IN ITEMS html pdf rtf man)
        install_doxydoc (\${FMT})
      endforeach ()
      "
  )
  # done
  if (BASIS_VERBOSE)
    message (STATUS "Adding documentation ${TARGET_UID}... - done")
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add documentation target to be generated by Sphinx (sphinx-build).
#
# This function adds a build target to generate documentation from
# <a href="http://docutils.sourceforge.net/rst.html">reStructuredText</a>
# (.rst files) using <a href="http://sphinx.pocoo.org/">Sphinx</a>.
#
# @param [in] TARGET_NAME Name of the documentation target.
# @param [in] ARGN        List of arguments. The valid arguments are:
# @par
# <table border="0">
#   <tr>
#     @tp @b BUILDER(S) builder... @endtp
#     <td>Sphinx builders to use. For each named builder, a build target
#         named &lt;TARGET_NAME&gt;_&lt;builder&gt; is added.</td>
#   </tr>
#   <tr>
#     @tp @b DEFAULT_BUILDER builder @endtp
#     <td>Default Sphinx builder to associated with the @c TARGET_NAME
#         build target. Defaults to the first builder named by @c BUILDERS.</td>
#   </tr>
#   <tr>
#     @tp @b AUTHOR(S) name @endtp
#     <td>Names of authors who wrote this documentation.</td>
#   </tr>
#   <tr>
#     @tp @b COPYRIGHT text @endtp
#     <td>Copyright statement for generated files.</td>
#   </tr>
#   <tr>
#     @tp @b COMPONENT component @endtp
#     <td>Name of the component this documentation belongs to.
#         Defaults to @c BASIS_RUNTIME_COMPONENT.</td>
#   </tr>
#   <tr>
#     @tp @b DESTINATION dir @endtp
#     <td>Installation directory prefix. Used whenever there is no specific
#         destination specified for a particular Sphinx builder. Defaults to
#         @c INSTALL_&ltTARGET&gt;_DIR in case of HTML output if set.
#         Otherwise, the generated HTML files are not installed.</td>
#   </tr>
#   <tr>
#     @tp @b &lt;BUILDER&gt;_DESTINATION dir @endtp
#     <td>Installation directory for files generated by the specific builder.<td>
#   </tr>
#   <tr>
#     @tp @b EXTENSIONS ext... @endtp
#     <td>Names of Sphinx extensions to enable.</td>
#   </tr>
#   <tr>
#     @tp @b BREATHE target... @endtp
#     <td>Adds a project for the breathe extension which allows the
#         inclusion of in-source code documentation extracted by Doxygen.
#         For this to work, the specified Doxygen target has to be
#         configured with the XML output enabled.</td>
#   </tr>
#   <tr>
#     @tp @b DOXYLINK target... @endtp
#     <td>Adds a role for the doxylink Sphinx extension which allows to cross-reference
#         generated HTML API documentation generated by Doxygen.</td>
#   </tr>
#   <tr>
#     @tp @b DOXYLINK_URL url @endtp
#     <td>URL to Doxygen documentation. Use DOXYLINK_PREFIX and/or DOXYLINK_SUFFIX
#         instead if you use multiple Doxygen targets, where the target name is
#         part of the URL.</td>
#   </tr>
#   <tr>
#     @tp @b DOXYLINK_PREFIX url @endtp
#     <td>Prefix to use for links to Doxygen generated documentation pages
#         as generated by the doxylink Sphinx extension. If this prefix does
#         not start with a protocol such as http:// or https://, it is prefixed
#         to the default path determined by this function relative to the build
#         or installed Doxygen documentation.</td>
#   </tr>
#   <tr>
#     @tp @b DOXYLINK_SUFFIX suffix @endtp
#     <td>Suffix for links to Doxygen generated documentation pages as generated
#         by the doxylink Sphinx extension.</td>
#   </tr>
#   <tr>
#     @tp @b DOXYDOC target... @endtp
#     <td>Alias for both @c BREATHE and @c DOXYLINK options.</td>
#   </tr>
#   <tr>
#     @tp @b CONFIG_FILE file @endtp
#     <td>Sphinx configuration file. Defaults to @c BASIS_SPHINX_CONFIG.</td>
#   </tr>
#   <tr>
#     @tp @b SOURCE_DIRECTORY @endtp
#     <td>Root directory of Sphinx source files.
#         Defaults to the current source directory or, if a subdirectory
#         named @c TARGET_NAME in lowercase only exists, to this subdirectory.</td>
#   </tr>
#   <tr>
#     @tp @b OUTPUT_DIRECTORY @endtp
#     <td>Root output directory for generated files. Defaults to the binary
#         directory corresponding to the set @c SOURCE_DIRECTORY.</td>
#   </tr>
#   <tr>
#     @tp @b TAG tag @endtp
#     <td>Tag argument of <tt>sphinx-build</tt>.</td>
#   </tr>
#   <tr>
#     @tp @b TEMPLATES_PATH @endtp
#     <td>Path to template files. Defaults to <tt>SOURCE_DIRECTORY/templates/</tt>.</td>
#   </tr>
#   <tr>
#     @tp @b MASTER_DOC name @endtp
#     <td>Name of master document. Defaults to <tt>index</tt>.</td>
#   </tr>
#   <tr>
#     @tp @b HTML_TITLE title @endtp
#     <td>Title of HTML web site.</td>
#   </tr>
#   <tr>
#     @tp @b HTML_THEME theme @endtp
#     <td>Name of HTML theme. Defaults to the @c sbia theme included with BASIS.</td>
#   </tr>
#   <tr>
#     @tp @b HTML_THEME_PATH dir @endtp
#     <td>Directory of HTML theme. Defaults to @c BASIS_SPHINX_HTML_THEME_PATH.</td>
#   </tr>
#   <tr>
#     @tp @b HTML_LOGO file @endtp
#     <td>Logo to display in sidebar of HTML pages.</td>
#   </tr>
#   <tr>
#     @tp @b HTML_STATIC_PATH dir @endtp
#     <td>Directory for static files of HTML pages. Defaults to <tt>SOURCE_DIRECTORY/static/</tt>.</td>
#   </tr>
#   <tr>
#     @tp @b HTML_SIDEBARS name... @endtp
#     <td>Names of HTML template files for sidebar(s). Defaults to none if not specified.
#         Valid default templates are @c localtoc, @c globaltoc, @c searchbox, @c relations,
#         @c sourcelink. See <a href="http://sphinx.pocoo.org/config.html#confval-html_sidebars">
#         Shinx documentation of html_sidebars option</a>. Custom templates can be used as
#         well by copying the template <tt>.html</tt> file to the @c TEMPLATES_PATH directory.</td>
#   </tr>
#   <tr>
#     @tp @b LATEX_TITLE title @endtp
#     <td>Title for LaTeX/PDF output. Defaults to title of <tt>index.rst</tt>.</td>
#   </tr>
#   <tr>
#     @tp @b LATEX_DOCUMENT_CLASS howto|manual @endtp
#     <td>Document class to use by @c latex builder.</td>
#   </tr>
#   <tr>
#     @tp @b MAN_SECTION num @endtp
#     <td>Section number for manual pages generated by @c man builder.</td>
#   </tr>
# </table>
#
# @sa basis_add_doc()
function (basis_add_sphinx_doc TARGET_NAME)
  # check target name
  basis_check_target_name ("${TARGET_NAME}")
  basis_make_target_uid (TARGET_UID "${TARGET_NAME}")
  string (TOLOWER "${TARGET_NAME}" TARGET_NAME_LOWER)
  string (TOUPPER "${TARGET_NAME}" TARGET_NAME_UPPER)
  # verbose output
  if (BASIS_VERBOSE)
    message (STATUS "Adding documentation ${TARGET_UID}...")
  endif ()
  # parse arguments
  set (ONE_ARG_OPTIONS
    COMPONENT
    DEFAUL_BUILDER
    DESTINATION HTML_DESTINATION MAN_DESTINATION TEXINFO_DESTINATION
    CONFIG_FILE
    SOURCE_DIRECTORY OUTPUT_DIRECTORY OUTPUT_NAME TAG
    COPYRIGHT MASTER_DOC
    HTML_TITLE HTML_THEME HTML_LOGO HTML_THEME_PATH
    LATEX_TITLE LATEX_DOCUMENT_CLASS
    MAN_SECTION
    DOXYLINK_URL DOXYLINK_PREFIX DOXYLINK_SUFFIX
  )
  # note that additional multiple value arguments are parsed later on below
  # this is necessary b/c all unparsed arguments are considered to be options
  # of the used HTML theme
  CMAKE_PARSE_ARGUMENTS (SPHINX "" "${ONE_ARG_OPTIONS}" "" ${ARGN})
  # component
  if (NOT SPHINX_COMPONENT)
    set (SPHINX_COMPONENT "${BASIS_RUNTIME_COMPONENT}")
  endif ()
  if (NOT SPHINX_COMPONENT)
    set (SPHINX_COMPONENT "Unspecified")
  endif ()
  # find Sphinx
  find_package (Sphinx)
  if (NOT Sphinx-build_EXECUTABLE)
    if (BUILD_DOCUMENTATION)
      message (FATAL_ERROR "Command sphinx-build not found! Either install Sphinx and/or set Sphinx-build_EXECUTABLE or disable BUILD_DOCUMENTATION.")
    endif ()
    message (STATUS "Command sphinx-build not found. Generation of ${TARGET_UID} documentation disabled.")
    if (BASIS_VERBOSE)
      message (STATUS "Adding documentation ${TARGET_UID}... - skipped")
    endif ()
    return ()
  endif ()
  # parse remaining arguments
  set (SPHINX_HTML_THEME_OPTIONS)
  set (SPHINX_BUILDERS)
  set (SPHINX_AUTHORS)
  set (SPHINX_EXTENSIONS)
  set (SPHINX_BREATHE_TARGETS)
  set (SPHINX_DOXYLINK_TARGETS)
  set (SPHINX_HTML_SIDEBARS)
  set (SPHINX_TEMPLATES_PATH)
  set (SPHINX_HTML_STATIC_PATH)
  set (SPHINX_EXCLUDE_PATTERNS)
  set (SPHINX_DEPENDS)
  set (OPTION_NAME)
  set (OPTION_VALUE)
  set (OPTION_PATTERN "(authors?|builders?|extensions|breathe|doxylink|doxydoc|html_sidebars|templates_path|html_static_path|exclude_patterns)")
  foreach (ARG IN LISTS SPHINX_UNPARSED_ARGUMENTS)
    if (NOT OPTION_NAME OR ARG MATCHES "^[A-Z_]+$")
      # SPHINX_HTML_THEME_OPTIONS
      if (OPTION_NAME AND NOT OPTION_NAME MATCHES "^${OPTION_PATTERN}$")
        if (NOT OPTION_VALUE)
          message (FATAL_ERROR "Option ${OPTION_NAME} is missing an argument!")
        endif ()
        list (LENGTH OPTION_VALUE NUM)
        if (NUM GREATER 1)
          basis_list_to_delimited_string (OPTION_VALUE ", " NOAUTOQUOTE ${OPTION_VALUE})
          set (OPTION_VALUE "[${OPTION_VALUE}]")
        endif ()
        list (APPEND SPHINX_HTML_THEME_OPTIONS "'${OPTION_NAME}': ${OPTION_VALUE}")
      endif ()
      # name of next option
      set (OPTION_NAME "${ARG}")
      set (OPTION_VALUE)
      string (TOLOWER "${OPTION_NAME}" OPTION_NAME)
    # BUILDER option
    elseif (OPTION_NAME MATCHES "^builders?$")
      if (ARG MATCHES "html dirhtml singlehtml pdf latex man text texinfo linkcheck")
        message (FATAL_ERROR "Invalid/Unsupported Sphinx builder: ${ARG}")
      endif ()
      list (APPEND SPHINX_BUILDERS "${ARG}")
    # AUTHORS option
    elseif (OPTION_NAME MATCHES "^authors?$")
      list (APPEND SPHINX_AUTHORS "'${ARG}'")
    # EXTENSIONS option
    elseif (OPTION_NAME MATCHES "^extensions$")
      # built-in extension
      if (ARG MATCHES "^(autodoc|autosummary|doctest|intersphinx|pngmath|jsmath|mathjax|graphvis|inheritance_graph|ifconfig|coverage|todo|extlinks|viewcode)$")
        set (ARG "sphinx.ext.${CMAKE_MATCH_0}")
      # map originial name of extensions included with BASIS
      elseif (ARG MATCHES "^sphinx-contrib.(doxylink)$")
        set (ARG "${CMAKE_MATCH_1}")
      endif ()
      list (APPEND SPHINX_EXTENSIONS "'${ARG}'")
    # DOXYDOC
    elseif (OPTION_NAME MATCHES "^doxydoc$")
      list (APPEND SPHINX_BREATHE_TARGETS  "${ARG}")
      list (APPEND SPHINX_DOXYLINK_TARGETS "${ARG}")
    # BREATHE
    elseif (OPTION_NAME MATCHES "^breathe$")
      list (APPEND SPHINX_BREATHE_TARGETS "${ARG}")
    # DOXYLINK
    elseif (OPTION_NAME MATCHES "^doxylink$")
      list (APPEND SPHINX_DOXYLINK_TARGETS "${ARG}")
    # HTML_SIDEBARS
    elseif (OPTION_NAME MATCHES "^html_sidebars$")
      if (NOT ARG MATCHES "\\.html?$")
        set (ARG "${ARG}.html")
      endif ()
      list (APPEND SPHINX_HTML_SIDEBARS "'${ARG}'")
    # TEMPLATES_PATH
    elseif (OPTION_NAME MATCHES "^templates_path$")
      list (APPEND SPHINX_TEMPLATES_PATH "'${ARG}'")
    # HTML_STATIC_PATH
    elseif (OPTION_NAME MATCHES "^html_static_path$")
      list (APPEND SPHINX_HTML_STATIC_PATH "'${ARG}'")
    # EXCLUDE_PATTERNS
    elseif (OPTION_NAME MATCHES "^exclude_patterns$")
      list (APPEND SPHINX_EXCLUDE_PATTERNS "'${ARG}'")
    # value of theme option
    else ()
      if (ARG MATCHES "^(TRUE|FALSE)$")
        string (TOLOWER "${ARG}" "${ARG}")
      endif ()
      if (NOT ARG MATCHES "^\\[.*\\]$|^{.*}$")
        set (ARG "'${ARG}'")
      endif ()
      list (APPEND OPTION_VALUE "${ARG}")
    endif ()
  endforeach ()
  # append parsed option setting to SPHINX_HTML_THEME_OPTIONS
  if (OPTION_NAME AND NOT OPTION_NAME MATCHES "^${OPTION_PATTERN}$")
    if (NOT OPTION_VALUE)
      message (FATAL_ERROR "Option ${OPTION_NAME} is missing an argument!")
    endif ()
    list (LENGTH OPTION_VALUE NUM)
    if (NUM GREATER 1)
      basis_list_to_delimited_string (OPTION_VALUE ", " NOAUTOQUOTE ${OPTION_VALUE})
      set (OPTION_VALUE "[${OPTION_VALUE}]")
    endif ()
    list (APPEND SPHINX_HTML_THEME_OPTIONS "'${OPTION_NAME}': ${OPTION_VALUE}")
  endif ()
  # default builders
  if (NOT SPHINX_BUILDERS)
    set (SPHINX_BUILDERS html dirhtml singlehtml man pdf texinfo text linkcheck)
  endif ()
  if (SPHINX_DEFAULT_BUILDER)
    list (FIND SPHINX_BUILDERS "${SPHINX_DEFAULT_BUILDER}" IDX)
    if (IDX EQUAL -1)
      list (INSERT SPHINX_BUILDERS 0 "${SPHINX_DEFAULT_BUILDER}")
    endif ()
  else ()
    list (GET SPHINX_BUILDERS 0 SPHINX_DEFAULT_BUILDER)
  endif ()
  # source directory
  if (NOT SPHINX_SOURCE_DIRECTORY)
    if (IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME}")
      set (SPHINX_SOURCE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME}")
    else ()
      set (SPHINX_SOURCE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    endif ()
  elseif (NOT IS_ABSOLUTE "${SPHINX_SOURCE_DIRECTORY}")
    get_filename_component (SPHINX_SOURCE_DIRECTORY "${SPHINX_SOURCE_DIRECTORY}" ABSOLUTE)
  endif ()
  # output directories
  if (NOT SPHINX_OUTPUT_NAME)
    set (SPHINX_OUTPUT_NAME "${PROJECT_NAME}")
  endif ()
  if (NOT SPHINX_OUTPUT_DIRECTORY)
    if (IS_ABSOLUTE "${SPHINX_OUTPUT_NAME}")
      get_filename_component (SPHINX_OUTPUT_DIRECTORY "${SPHINX_OUTPUT_NAME}" PATH)
    else ()
      basis_get_relative_path (SPHINX_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" "${SPHINX_SOURCE_DIRECTORY}")
    endif ()
  endif ()
  if (NOT IS_ABSOLUTE "${SPHINX_OUTPUT_DIRECTORY}")
    set (SPHINX_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${SPHINX_OUTPUT_DIRECTORY}")
  endif ()
  foreach (b IN LISTS SPHINX_BUILDERS)
    string (TOUPPER "${b}" B)
    if (SPHINX_${B}_OUTPUT_DIRECTORY)
      if (NOT IS_ABSOLUTE "${SPHINX_${B}_OUTPUT_DIRECTORY}")
        set (SPHINX_${B}_OUTPUT_DIRECTORY "${SPHINX_OUTPUT_DIRECTORY}/${SPHINX_${B}_OUTPUT_DIRECTORY}")
      endif ()
    else ()
      set (SPHINX_${B}_OUTPUT_DIRECTORY "${SPHINX_OUTPUT_DIRECTORY}/${b}")
    endif ()
  endforeach ()
  if (IS_ABSOLUTE "${SPHINX_OUTPUT_NAME}")
    basis_get_relative_path (SPHINX_OUTPUT_NAME "${SPHINX_OUTPUT_DIRECTORY}" NAME_WE)
  endif ()
  # configuration directory
  basis_get_relative_path (SPHINX_CONFIG_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" "${SPHINX_SOURCE_DIRECTORY}")
  set (SPHINX_CONFIG_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${SPHINX_CONFIG_DIRECTORY}")
  # build configuration
  if (NOT SPHINX_MASTER_DOC)
    set (SPHINX_MASTER_DOC "index")
  endif ()
  if (NOT SPHINX_TEMPLATES_PATH AND EXISTS "${SPHINX_SOURCE_DIRECTORY}/templates")
    set (SPHINX_TEMPLATES_PATH "${SPHINX_SOURCE_DIRECTORY}/templates")
  endif ()
  if (NOT SPHINX_HTML_STATIC_PATH AND EXISTS "${SPHINX_SOURCE_DIRECTORY}/static")
    set (SPHINX_HTML_STATIC_PATH "${SPHINX_SOURCE_DIRECTORY}/static")
  endif ()
  if (NOT SPHINX_HTML_THEME)
    set (SPHINX_HTML_THEME "${BASIS_SPHINX_HTML_THEME}")
  endif ()
  if (NOT SPHINX_UNPARSED_ARGUMENTS AND SPHINX_HTML_THEME STREQUAL BASIS_SPHINX_HTML_THEME)
    set (SPHINX_UNPARSED_ARGUMENTS ${BASIS_SPHINX_HTML_THEME_OPTIONS})
  endif () 
  if (NOT SPHINX_LATEX_DOCUMENTCLASS)
    set (SPHINX_LATEX_DOCUMENTCLASS "howto")
  endif ()
  if (NOT SPHINX_MAN_SECTION)
    set (SPHINX_MAN_SECTION 1)
  endif ()
  # installation directories
  set (INSTALL_${TARGET_NAME_UPPER}_DIR "" CACHE PATH "Installation directory for ${TARGET_NAME_UPPER}.")
  mark_as_advanced (INSTALL_${TARGET_NAME_UPPER}_DIR)
  foreach (b IN LISTS SPHINX_BUILDERS)
    string (TOUPPER "${b}" B)
    if (NOT SPHINX_${B}_DESTINATION)
      if (SPHINX_DESTINATION)                           
        set (SPHINX_${B}_DESTINATION "${DESTINATION}") # common destination
      elseif (INSTALL_${TARGET_NAME_UPPER}_DIR)
        set (SPHINX_${B}_DESTINATION "${INSTALL_${TARGET_NAME_UPPER}_DIR}") # global setting
      elseif (BUILDER MATCHES "text")
        set (SPHINX_${B}_DESTINATION "${INSTALL_DOC_DIR}/${TARGET_NAME_LOWER}")
      elseif (BUILDER MATCHES "man")
        if (INSTALL_MAN_DIR)
          set (SPHINX_${B}_DESTINATION "${INSTALL_MAN_DIR}/man${SPHINX_MAN_SECTION}") # default for manual pages
        endif ()
      elseif (BUILDER MATCHES "texinfo")
        if (INSTALL_TEXINFO_DIR)
          set (SPHINX_${B}_DESTINATION "${INSTALL_TEXINFO_DIR}") # default for Texinfo files
        endif ()
      elseif (NOT BUILDER MATCHES "html") # do not install excludes by default
        set (SPHINX_${B}_DESTINATION "${INSTALL_DOC_DIR}") # default location
      endif ()
    endif ()
  endforeach ()
  if (SPHINX_HTML_DESTINATION)
    foreach (b IN LISTS SPHINX_BUILDERS)
      if (b MATCHES "(dir|single)html")
        string (TOUPPER "${b}" B)
        if (NOT SPHINX_${B}_DESTINATION)
          set (SPHINX_${B}_DESTINATION "${SPHINX_HTML_DESTINATION}")
        endif ()
      endif ()
    endforeach ()
  endif ()
  # enable required extension
  if (SPHINX_DOXYLINK_TARGETS AND NOT SPHINX_EXTENSIONS MATCHES "(^|;)?doxylink(;|$)?")
    list (APPEND SPHINX_EXTENSIONS "'doxylink'")
  endif ()
  if (SPHINX_BREATHE_TARGETS AND NOT SPHINX_EXTENSIONS MATCHES "(^|;)?breathe(;|$)?")
    list (APPEND SPHINX_EXTENSIONS "'breathe'")
  endif ()
  # doxylink configuration
  foreach (TARGET IN LISTS SPHINX_DOXYLINK_TARGETS)
    basis_get_target_uid (UID "${TARGET}")
    get_target_property (TYPE ${UID} BASIS_TYPE)
    if (NOT TYPE MATCHES "Doxygen")
      message (FATAL_ERROR "Invalid argument for DOXYLINK: Target ${UID} either unknown or it is not a Doxygen target!")
    endif ()
    get_target_property (DOXYGEN_OUTPUT ${UID} OUTPUT)
    if (NOT DOXYGEN_OUTPUT MATCHES "html")
      message (FATAL_ERROR "Doxygen target ${UID} was not configured to generate HTML output! This output is required by the doxylink Sphinx extension.")
    endif ()
    get_target_property (DOXYGEN_TAGFILE        ${UID} TAGFILE)
    get_target_property (DOXYGEN_HTML_DIRECTORY ${UID} HTML_INSTALL_DIRECTORY)
    set (DOXYLINK_PATH)
    if (SPHINX_DOXYLINK_URL)
      set (DOXYLINK_PATH "${SPHINX_DOXYLINK_URL}")
    elseif (SPHINX_DOXYLINK_PREFIX MATCHES "^[a-z]://")
      set (DOXYLINK_PATH "${SPHINX_DOXYLINK_PREFIX}${TARGET}${SPHINX_DOXYLINK_SUFFIX}")
    else ()
      set (DOXYLINK_BASE_DIR)
      if (DOXYGEN_HTML_DIRECTORY)
        if (SPHINX_DOXYLINK_BASE_DIR)
          set (DOXYLINK_BASE_DIR "${SPHINX_DOXYLINK_BASE_DIR}")
        elseif (SPHINX_HTML_INSTALL_DIRECTORY)
          set (DOXYLINK_BASE_DIR "${SPHINX_HTML_INSTALL_DIRECTORY}")
        endif ()
      else ()
        get_target_property (DOXYGEN_HTML_DIRECTORY ${UID} HTML_OUTPUT_DIRECTORY)
        if (SPHINX_DOXYLINK_BASE_DIR)
          set (DOXYLINK_BASE_DIR "${SPHINX_DOXYLINK_BASE_DIR}")
        else ()
          set (DOXYLINK_BASE_DIR "${SPHINX_HTML_OUTPUT_DIRECTORY}")
        endif ()
      endif ()
      if (DOXYLINK_BASE_DIR)
        basis_get_relative_path (DOXYLINK_PATH "${DOXYLINK_BASE_DIR}" "${DOXYGEN_HTML_DIRECTORY}")
      else ()
        set (DOXYLINK_PATH "${TARGET}") # safe fall back
      endif ()
      set (DOXYLINK_PATH "${SPHINX_DOXYLINK_PREFIX}${DOXYLINK_PATH}${SPHINX_DOXYLINK_SUFFIX}")
    endif ()
    list (APPEND SPHINX_DOXYLINK "'${TARGET}': ('${DOXYGEN_TAGFILE}', '${DOXYLINK_PATH}')")
    #list (APPEND SPHINX_DEPENDS ${UID}) # Doxygen re-runs every time...
  endforeach ()
  # breathe configuration
  set (SPHINX_BREATHE_PROJECTS)
  set (SPHINX_BREATHE_DEFAULT_PROJECT)
  foreach (TARGET IN LISTS SPHINX_BREATHE_TARGETS)
    basis_get_target_uid (UID "${TARGET}")
    get_target_property (TYPE ${UID} BASIS_TYPE)
    if (NOT TYPE MATCHES "Doxygen")
      message (FATAL_ERROR "Invalid argument for BREATHE_PROJECTS: Target ${UID} either unknown or it is not a Doxygen target!")
    endif ()
    get_target_property (DOXYGEN_OUTPUT ${UID} OUTPUT)
    if (NOT DOXYGEN_OUTPUT MATCHES "xml")
      message (FATAL_ERROR "Doxygen target ${UID} was not configured to generate XML output! This output is required by the Sphinx extension breathe.")
    endif ()
    get_target_property (DOXYGEN_OUTPUT_DIRECTORY ${UID} XML_OUTPUT_DIRECTORY)
    list (APPEND SPHINX_BREATHE_PROJECTS "'${TARGET}': '${DOXYGEN_OUTPUT_DIRECTORY}'")
    if (NOT SPHINX_BREATHE_DEFAULT_PROJECT)
      set (SPHINX_BREATHE_DEFAULT_PROJECT "${TARGET}")
    endif ()
    #list (APPEND SPHINX_DEPENDS ${UID}) # Doxygen re-runs every time...
  endforeach ()
  # turn CMake lists into Python lists
  basis_list_to_delimited_string (SPHINX_EXTENSIONS         ", " NOAUTOQUOTE ${SPHINX_EXTENSIONS})
  basis_list_to_delimited_string (SPHINX_HTML_THEME_OPTIONS ", " NOAUTOQUOTE ${SPHINX_HTML_THEME_OPTIONS})
  basis_list_to_delimited_string (SPHINX_AUTHORS            ", " NOAUTOQUOTE ${SPHINX_AUTHORS})
  basis_list_to_delimited_string (SPHINX_DOXYLINK           ", " NOAUTOQUOTE ${SPHINX_DOXYLINK})
  basis_list_to_delimited_string (SPHINX_BREATHE_PROJECTS   ", " NOAUTOQUOTE ${SPHINX_BREATHE_PROJECTS})
  basis_list_to_delimited_string (SPHINX_HTML_SIDEBARS      ", " NOAUTOQUOTE ${SPHINX_HTML_SIDEBARS})
  basis_list_to_delimited_string (SPHINX_TEMPLATES_PATH     ", " NOAUTOQUOTE ${SPHINX_TEMPLATES_PATH})
  basis_list_to_delimited_string (SPHINX_HTML_STATIC_PATH   ", " NOAUTOQUOTE ${SPHINX_HTML_STATIC_PATH})
  basis_list_to_delimited_string (SPHINX_EXCLUDE_PATTERNS   ", " NOAUTOQUOTE ${SPHINX_EXCLUDE_PATTERNS})
  # configuration file
  if (NOT SPHINX_CONFIG_FILE)
    set (SPHINX_CONFIG_FILE "${BASIS_SPHINX_CONFIG}")
  endif ()
  get_filename_component (SPHINX_CONFIG_FILE "${SPHINX_CONFIG_FILE}" ABSOLUTE)
  if (EXISTS "${SPHINX_CONFIG_FILE}")
    configure_file ("${SPHINX_CONFIG_FILE}" "${SPHINX_CONFIG_DIRECTORY}/conf.py" @ONLY)
  elseif (EXISTS "${SPHINX_CONFIG_FILE}.in")
    configure_file ("${SPHINX_CONFIG_FILE}.in" "${SPHINX_CONFIG_DIRECTORY}/conf.py" @ONLY)
  else ()
    message (FATAL_ERROR "Missing Sphinx configuration file ${SPHINX_CONFIG_FILE}!")
  endif ()
  # add target to build documentation
  set (OPTIONS -a -N -n)
  if (NOT BASIS_VERBOSE)
    list (APPEND OPTIONS "-q")
  endif ()
  foreach (TAG IN LISTS SPHINX_TAG)
    list (APPEND OPTIONS "-t" "${TAG}")
  endforeach ()
  add_custom_target (${TARGET_UID}_all) # target to run all builders
  foreach (BUILDER IN LISTS SPHINX_BUILDERS)
    set (SPHINX_BUILDER "${BUILDER}")
    set (SPHINX_POST_COMMAND)
    if (BUILDER MATCHES "pdf|texinfo")
      if (BUILDER MATCHES "pdf")
        set (SPHINX_BUILDER "latex")
      endif ()
      set (SPHINX_POST_COMMAND COMMAND make -C "${SPHINX_OUTPUT_DIRECTORY}/${SPHINX_BUILDER}")
    endif ()
    add_custom_target (
      ${TARGET_UID}_${BUILDER}
          "${Sphinx-build_EXECUTABLE}" ${OPTIONS}
              -b ${SPHINX_BUILDER}
              -c "${SPHINX_CONFIG_DIRECTORY}"
              -d "${SPHINX_CONFIG_DIRECTORY}/doctrees"
              "${SPHINX_SOURCE_DIRECTORY}"
              "${SPHINX_OUTPUT_DIRECTORY}/${SPHINX_BUILDER}"
          ${SPHINX_POST_COMMAND}
          ${OPTDEPENDS}
      WORKING_DIRECTORY "${SPHINX_CONFIG_DIRECTORY}"
      COMMENT "Building documentation ${TARGET_UID} (${BUILDER})..."
    )
    if (SPHINX_DEPENDS)
      add_dependencies (${TARGET_UID}_${BUILDER} ${SPHINX_DEPENDS})
    endif ()
    add_dependencies (${TARGET_UID}_all ${TARGET_UID}_${BUILDER})
    # cleanup on "make clean"
    set_property (
      DIRECTORY
      APPEND PROPERTY
        ADDITIONAL_MAKE_CLEAN_FILES
          "${SPHINX_OUTPUT_DIRECTORY}"
    )
  endforeach ()
  # add general target which depends on default builder only
  if (BUILD_DOCUMENTATION AND BASIS_ALL_DOC)
    add_custom_target (${TARGET_UID} ALL)
  else ()
    add_custom_target (${TARGET_UID} ALL)
  endif ()
  add_dependencies (${TARGET_UID} ${TARGET_UID}_${SPHINX_DEFAULT_BUILDER})
  # add general "doc" target
  if (NOT TARGET doc)
    add_custom_target (doc)
  endif ()
  add_dependencies (doc ${TARGET_UID})
  # memorize important target properties
  set_target_properties (
    ${TARGET_UID}
    PROPERTIES
      BASIS_TYPE       Sphinx
      BUILDERS         "${SPHINX_BUILDERS}"
      SOURCE_DIRECTORY "${SPHINX_SOURCE_DIRECTORY}"
      OUTPUT_DIRECTORY "${SPHINX_OUTPUT_DIRECTORY}"
      CONFIG_DIRECTORY "${SPHINX_CONFIG_DIRECTORY}"
  )
  foreach (b IN LISTS SPHINX_BUILDERS)
    string (TOUPPER ${b} B)
    set_target_properties (${TARGET_UID} PROPERTIES ${B}_INSTALL_DIRECTORY "${SPHINX_${B}_DESTINATION}")
  endforeach ()
  # cleanup on "make clean"
  set_property (
    DIRECTORY
    APPEND PROPERTY
      ADDITIONAL_MAKE_CLEAN_FILES
        "${SPHINX_CONFIG_DIRECTORY}/doctrees"
  )
  # install documentation
  install (
    CODE
      "
      set (HTML_DESTINATION    \"${SPHINX_HTML_DESTINATION}\")
      set (PDF_DESTINATION     \"${SPHINX_PDF_DESTINATION}\")
      set (LATEX_DESTINATION   \"${SPHINX_LATEX_DESTINATION}\")
      set (MAN_DESTINATION     \"${SPHINX_MAN_DESTINATION}\")
      set (TEXINFO_DESTINATION \"${SPHINX_TEXINFO_DESTINATION}\")
      set (TEXT_DESTINATION    \"${SPHINX_TEXT_DESTINATION}\")

      function (install_sphinx_doc BUILDER)
        if (BUILDER MATCHES \"pdf\")
          set (SPHINX_BUILDER \"latex\")
        else ()
          set (SPHINX_BUILDER \"\${BUILDER}\")
        endif ()
        string (TOUPPER \"\${BUILDER}\" BUILDER_UPPER)
        set (INSTALL_PREFIX \"\${\${BUILDER_UPPER}_DESTINATION}\")
        if (NOT INSTALL_PREFIX)
          return ()
        elseif (NOT IS_ABSOLUTE \"\${INSTALL_PREFIX}\")
          set (INSTALL_PREFIX \"${INSTALL_PREFIX}/\${INSTALL_PREFIX}\")
        endif ()
        set (EXT)
        if (BUILDER MATCHES \"pdf\")
          set (EXT \".pdf\")
        elseif (BUILDER MATCHES \"man\")
          set (EXT \".?\")
        elseif (BUILDER MATCHES \"texinfo\")
          set (EXT \".info\")
        endif ()
        file (
          GLOB_RECURSE
            FILES
          RELATIVE \"${SPHINX_OUTPUT_DIRECTORY}/\${SPHINX_BUILDER}\"
            \"${SPHINX_OUTPUT_DIRECTORY}/\${SPHINX_BUILDER}/*\${EXT}\"
        )
        foreach (F IN LISTS FILES)
          if (NOT F MATCHES \"\\\\.buildinfo\")
            set (RC 1)
            if (NOT BUILDER MATCHES \"texinfo\")
              execute_process (
                COMMAND \"${CMAKE_COMMAND}\" -E compare_files
                    \"${SPHINX_OUTPUT_DIRECTORY}/\${SPHINX_BUILDER}/\${F}\"
                    \"\${INSTALL_PREFIX}/\${F}\"
                RESULT_VARIABLE RC
                OUTPUT_QUIET
                ERROR_QUIET
              )
            endif ()
            if (RC EQUAL 0)
              message (STATUS \"Up-to-date: \${INSTALL_PREFIX}/\${F}\")
            else ()
              message (STATUS \"Installing: \${INSTALL_PREFIX}/\${F}\")
              if (BUILDER MATCHES \"texinfo\")
                if (EXISTS \"\${INSTALL_PREFIX}/dir\")
                  execute_process (
                    COMMAND install-info
                        \"${SPHINX_OUTPUT_DIRECTORY}/\${SPHINX_BUILDER}/\${F}\"
                        \"\${INSTALL_PREFIX}/dir\"
                    RESULT_VARIABLE RC
                    OUTPUT_QUIET
                    ERROR_QUIET
                  )
                else ()
                  execute_process (
                    COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different
                        \"${SPHINX_OUTPUT_DIRECTORY}/\${SPHINX_BUILDER}/\${F}\"
                        \"\${INSTALL_PREFIX}/dir\"
                    RESULT_VARIABLE RC
                    OUTPUT_QUIET
                    ERROR_QUIET
                  )
                endif ()
              else ()
                execute_process (
                  COMMAND \"${CMAKE_COMMAND}\" -E copy_if_different
                      \"${SPHINX_OUTPUT_DIRECTORY}/\${SPHINX_BUILDER}/\${F}\"
                      \"\${INSTALL_PREFIX}/\${F}\"
                  RESULT_VARIABLE RC
                  OUTPUT_QUIET
                  ERROR_QUIET
                )
              endif ()
              if (RC EQUAL 0)
                # also remember .info files for deinstallation via install-info --delete
                list (APPEND CMAKE_INSTALL_MANIFEST_FILES \"\${INSTALL_PREFIX}/\${F}\")
              else ()
                message (STATUS \"Failed to install \${INSTALL_PREFIX}/\${F}\")
              endif ()
            endif ()
          endif ()
        endforeach ()
      endfunction ()

      set (BUILDERS \"${SPHINX_BUILDERS}\")
      set (HTML_INSTALLED FALSE)
      foreach (BUILDER IN LISTS BUILDERS)
        if ((BUILDER MATCHES \"html\" AND NOT HTML_INSTALLED) OR
              (BUILDER MATCHES \"texinfo|man\" AND UNIX) OR
              NOT BUILDER MATCHES \"html|texinfo|man|latex|linkcheck\")
          install_sphinx_doc (\${BUILDER})
          if (BUILDER MATCHES \"html\")
            set (HTML_INSTALLED TRUE)
          endif ()
        endif ()
      endforeach ()
      "
  )
  # done
  if (BASIS_VERBOSE)
    message (STATUS "Adding documentation ${TARGET_UID}... - done")
  endif ()
endfunction ()

# ============================================================================
# change log
# ============================================================================

# ----------------------------------------------------------------------------
## @brief Add target for generation of ChangeLog file.
#
# The ChangeLog is either generated from the Subversion or Git log depending
# on which revision control system is used by the project. Moreover, the
# project's source directory must be either a Subversion working copy or
# the root of a Git repository, respectively. In case of Subversion, if the
# command-line tool svn2cl(.sh) is installed, it is used to output a nicer
# formatted change log.
function (basis_add_changelog)
  basis_make_target_uid (TARGET_UID "changelog")

  option (BUILD_CHANGELOG "Request build and/or installation of the ChangeLog." OFF)
  mark_as_advanced (BUILD_CHANGELOG)
  set (CHANGELOG_FILE "${PROJECT_BINARY_DIR}/ChangeLog")

  if (BASIS_VERBOSE)
    message (STATUS "Adding ChangeLog...")
  endif ()

  if (BUILD_CHANGELOG)
    set (_ALL "ALL")
  else ()
    set (_ALL)
  endif ()

  set (DISABLE_BUILD_CHANGELOG FALSE)

  # --------------------------------------------------------------------------
  # generate ChangeLog from Subversion history
  if (EXISTS "${PROJECT_SOURCE_DIR}/.svn")
    find_package (Subversion QUIET)
    if (Subversion_FOUND)

      if (_ALL)
        message ("Generation of ChangeLog enabled as part of ALL."
                 " Be aware that the ChangeLog generation from the Subversion"
                 " commit history can take several minutes and may require the"
                 " input of your Subversion repository credentials during the"
                 " build. If you would like to build the ChangeLog separate"
                 " from the rest of the software package, disable the option"
                 " BUILD_CHANGELOG. You can then build the changelog target"
                 " separate from ALL.")
      endif ()

      # using svn2cl command
      find_program (
        SVN2CL_EXECUTABLE
          NAMES svn2cl svn2cl.sh
          DOC   "The command line tool svn2cl."
      )
      mark_as_advanced (SVN2CL_EXECUTABLE)
      if (SVN2CL_EXECUTABLE)
        add_custom_target (
          ${TARGET_UID} ${_ALL}
          COMMAND "${SVN2CL_EXECUTABLE}"
              "--output=${CHANGELOG_FILE}"
              "--linelen=79"
              "--reparagraph"
              "--group-by-day"
              "--include-actions"
              "--separate-daylogs"
              "${PROJECT_SOURCE_DIR}"
          COMMAND "${CMAKE_COMMAND}"
              "-DCHANGELOG_FILE:FILE=${CHANGELOG_FILE}" -DINPUTFORMAT=SVN2CL
              -P "${BASIS_MODULE_PATH}/PostprocessChangeLog.cmake"
          WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
          COMMENT "Generating ChangeLog from Subversion log (using svn2cl)..."
        )
      # otherwise, use svn log output directly
      else ()
        add_custom_target (
          ${TARGET_UID} ${_ALL}
          COMMAND "${CMAKE_COMMAND}"
              "-DCOMMAND=${Subversion_SVN_EXECUTABLE};log"
              "-DWORKING_DIRECTORY=${PROJECT_SOURCE_DIR}"
              "-DOUTPUT_FILE=${CHANGELOG_FILE}"
              -P "${BASIS_SCRIPT_EXECUTE_PROCESS}"
          COMMAND "${CMAKE_COMMAND}"
              "-DCHANGELOG_FILE:FILE=${CHANGELOG_FILE}" -DINPUTFORMAT=SVN
              -P "${BASIS_MODULE_PATH}/PostprocessChangeLog.cmake"
          COMMENT "Generating ChangeLog from Subversion log..."
          VERBATIM
        )
      endif ()

    else ()
      message (STATUS "Project is SVN working copy but Subversion executable was not found."
                      " Generation of ChangeLog disabled.")
      set (DISABLE_BUILD_CHANGELOG TRUE)
    endif ()

  # --------------------------------------------------------------------------
  # generate ChangeLog from Git log
  elseif (EXISTS "${PROJECT_SOURCE_DIR}/.git")
    find_package (Git QUIET)
    if (GIT_FOUND)

      add_custom_target (
        ${TARGET_UID} ${_ALL}
        COMMAND "${CMAKE_COMMAND}"
            "-DCOMMAND=${GIT_EXECUTABLE};log;--date-order;--date=short;--pretty=format:%ad\ \ %an%n%n%w(79,8,10)* %s%n%n%b%n"
            "-DWORKING_DIRECTORY=${PROJECT_SOURCE_DIR}"
            "-DOUTPUT_FILE=${CHANGELOG_FILE}"
            -P "${BASIS_SCRIPT_EXECUTE_PROCESS}"
        COMMAND "${CMAKE_COMMAND}"
            "-DCHANGELOG_FILE=${CHANGELOG_FILE}" -DINPUTFORMAT=GIT
            -P "${BASIS_MODULE_PATH}/PostprocessChangeLog.cmake"
        COMMENT "Generating ChangeLog from Git log..."
        VERBATIM
      )

    else ()
      message (STATUS "Project is Git repository but Git executable was not found."
                      " Generation of ChangeLog disabled.")
      set (DISABLE_BUILD_CHANGELOG TRUE)
    endif ()

  # --------------------------------------------------------------------------
  # neither SVN nor Git repository
  else ()
    message (STATUS "Project is neither SVN working copy nor Git repository."
                    " Generation of ChangeLog disabled.")
    set (DISABLE_BUILD_CHANGELOG TRUE)
  endif ()

  # --------------------------------------------------------------------------
  # disable changelog target
  if (DISABLE_BUILD_CHANGELOG)
    set (BUILD_CHANGELOG OFF CACHE INTERNAL "" FORCE)
    if (BASIS_VERBOSE)
      message (STATUS "Adding ChangeLog... - skipped")
    endif ()
    return ()
  endif ()

  # --------------------------------------------------------------------------
  # cleanup on "make clean"
  set_property (DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${CHANGELOG_FILE}")

  # --------------------------------------------------------------------------
  # install ChangeLog
  install (
    FILES       "${CHANGELOG_FILE}"
    DESTINATION "${INSTALL_DOC_DIR}"
    COMPONENT   "${BASIS_RUNTIME_COMPONENT}"
    OPTIONAL
  )

  if (BASIS_VERBOSE)
    message (STATUS "Adding ChangeLog... - done")
  endif ()
endfunction ()
