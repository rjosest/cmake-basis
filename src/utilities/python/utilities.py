##############################################################################
# @file  utilities.py
# @brief Basic utility functions.
#
# Copyright (c) 2011, 2012 University of Pennsylvania. All rights reserved.<br />
# See http://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
#
# @ingroup BasisPythonUtilities
##############################################################################

"""
Basic utility functions.

This module defines BASIS utility functions whose implementations are not
project-specific, i.e., do not make use of particular project attributes such
as the name or version of the project. The utility functions defined by this
module are intended for use in Python scripts that are not build as part of a
particular BASIS project. Otherwise, the project-specific implementations
should be used instead, i.e., those defined by the basis.py module of the
project which is automatically added to the project during the configuration
of the build tree. This basis.py module and those submodules imported by it
are generated from template modules which are customized for the particular
project that is being build.

Copyright (c) 2011, 2012 University of Pennsylvania. All rights reserved.
See COPYING file or https://www.rad.upenn.edu/sbia/software/license.html.

Contact: SBIA Group <sbia-software at uphs.upenn.edu>

"""

## @addtogroup BasisPythonUtilities
# @{


# ============================================================================
# globals
# ============================================================================

import sys
import os.path
import subprocess

from .config import COPYRIGHT, LICENSE, CONTACT

# ============================================================================
# executable information
# ============================================================================

# ----------------------------------------------------------------------------
def print_contact(contact=CONTACT):
    """Print contact information.

    @param [in] contact Name of contact.

    """
    sys.stdout.write("Contact:\n  " + contact + "\n")

# ----------------------------------------------------------------------------
def print_version(name, version, project=None, copyright=COYRIGHT, license=LICENSE):
    """Print version information including copyright and license notices.

    @param [in] name      Name of executable. Should not be set programmatically
                          to the first argument of the @c __main__ module, but
                          a string literal instead.
    @param [in] version   Version of executable, e.g., release of project
                          this executable belongs to.
    @param [in] project   Name of project this executable belongs to.
                          If @c None or an empty string is given, no project
                          information is printed.
    @param [in] copyright The copyright notice. If @c None or an empty string,
                          no copyright notice is printed.
    @param [in] license   Information regarding licensing. If @c None or an
                          empty string, no license information is printed.

    """
    # program identification
    sys.stdout.write(name)
    if project and project != '':
        sys.stdout.write(' (')
        sys.stdout.write(project)
        sys.stdout.write(')')
    sys.stdout.write(' ')
    sys.stdout.write(version)
    sys.stdout.write('\n')
    # copyright notice
    if not copyright and copyright != '':
        sys.stdout.write("Copyright (c) ");
        sys.stdout.write(copyright)
        sys.stdout.write('\n')
    # license information
    if not license and license != '':
        sys.stdout.write(license)
        sys.stdout.write('\n')

# ----------------------------------------------------------------------------
def get_executable_path(name=None):
    """Get absolute path of executable file.

    This function determines the absolute file path of an executable. If no
    arguments are given, the absolute path of this executable is returned.
    Otherwise, the named command is searched in the system @c PATH and its
    absolute path returned if found. If the executable is not found, @c None
    is returned.

    @param [in] name Name of command or @c None.

    @returns Absolute path of executable or @c None if not found.
             If @p name is @c None, the path of this executable is returned.

    """
    path = None
    if name is None:
        path = os.path.realpath(sys.argv[0])
        if os.path.isdir(path): # interactive shell
            os.path.join(path, "<stdin>")
    else:
        from .which import which, WhichError
        try:
            path = which(name)
        except WhichError:
            pass
    return path

# ----------------------------------------------------------------------------
def get_executable_name(name=None):
    """Get name of executable file.

    @param [in] name Name of command or @c None.

    @returns Name of executable file or @c None if not found.
             If @p name is @c None, the name of this executable is returned.

    """
    path = get_executable_path(name)
    if path is None: return None
    return os.path.basename(path)

# ----------------------------------------------------------------------------
def get_executable_directory(name=None):
    """Get directory of executable file.

    @param [in] name Name of command or @c None.

    @returns Absolute path of directory containing executable or @c None if not found.
             If @p name is @c None, the directory of this executable is returned.

    """
    path = get_executable_path(name)
    if path is None: return None
    return os.path.dirname(path)

# ============================================================================
# command execution
# ============================================================================

# ----------------------------------------------------------------------------
class SubprocessError(Exception):
    """Exception thrown when command execution failed."""

    def __init__(self, msg):
        """Initialize exception, i.e., set message describing failure."""
        self._message = msg

    def __str__(self):
        """Return string representation of exception message."""
        return self._message

# ----------------------------------------------------------------------------
def to_quoted_string(args):
    """Convert list to double quoted string.

    @param [in] args List of arguments.

    @returns Double quoted string, i.e., string where array elements are separated
             by a space character and surrounded by double quotes if necessary.
             Double quotes within an array element are escaped with a backslash.

    """
    qargs = []
    re_quote_or_not = re.compile(r"'|\s")
    for arg in args:
        # escape double quotes
        arg = arg.replace('"', '\\"')
        # surround element by double quotes if necessary
        if re_quote_or_not.search(arg): qargs.append(''.join(['"', arg, '"']))
        else:                           qargs.append(arg)
    return ' '.join(qargs)

# ----------------------------------------------------------------------------
def split_quoted_string(args):
    """Split double quoted string."""
    from shlex import split
    return split(args)

# ----------------------------------------------------------------------------
def to_array_of_strings(args):
    """Convert list or double quoted string to array of strings.

    @param [in] args List or arguments or double quoted string.

    @returns List of strings.

    """
    if   type(args) is list: return [str(i) for i in args]
    elif type(args) is str:  return split_quoted_string(args);
    else: raise Exception("Argument must be either list or string")

# ----------------------------------------------------------------------------
def execute_process(args, quiet=False, stdout=False, allow_fail=False, verbose=0, simulate=False):
    """Execute command as subprocess.

    @param [in] args       Command with arguments given either as quoted string
                           or array of command name and arguments. In the latter
                           case, the array elements are converted to strings
                           using the built-in str() function. Hence, any type
                           which can be converted to a string is permitted.
                           The first argument must be the name or path of the
                           executable of the command.
    @param [in] quiet      Turns off output of @c stdout of child process to
                           stdout of parent process.
    @param [in] stdout     Whether to return the command output.
    @param [in] allow_fail If true, does not raise an exception if return
                           value is non-zero. Otherwise, a @c SubprocessError is
                           raised by this function.
    @param [in] verbose    Verbosity of output messages.
                           Does not affect verbosity of executed command.
    @param [in] simulate   Whether to simulate command execution only.

    @returns A tuple consisting of exit code of executed command and command
             output if both @p stdout and @p allow_fail are @c True.
             If only @p stdout is @c True, only the command output is returned.
             If only @p allow_fail is @c True, only the exit code is returned.
             Otherwise, this function always returns 0.

    @throws SubprocessError If command execution failed. This exception is not
                            raised if the command executed with non-zero exit
                            code but @p allow_fail set to @c True.

    """
    # convert args to list of strings
    args = to_array_of_strings(args)
    # get absolute path of executable
    path = get_executable_path(args[0])
    if not path: raise SubprocessError(args[0] + ": Command not found")
    args[0] = path
    # some verbose output
    if verbose > 0:
        sys.stdout.write('$ ')
        sys.stdout.write(to_quoted_string(args))
        if simulate: sys.stdout.write(' (simulated)')
        sys.stdout.write('\n')
    # execute command
    status = 0
    output = ''
    if not simulate:
        try:
            # open subprocess
            process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            # read stdout until EOF
            for line in process.stdout:
                if stdout:
                    output = output + line
                if not quiet:
                    print line.rstrip()
                    sys.stdout.flush()
            # wait until subprocess terminated and set exit code
            (out, err) = process.communicate()
            # print error messages of subprocess
            for line in err: sys.stderr.write(line);
            # get exit code
            status = process.returncode
        except OSError, e:
            raise SubprocessError(args[0] + ': ' + str(e))
        except Exception, e:
            msg  = "Exception while executing \"" + args[0] + "\"!\n"
            msg += "\tArguments: " + to_quoted_string(args[1:]) + '\n'
            msg += '\t' + str(e)
            raise SubprocessError(msg)
    # if command failed, throw an exception
    if status != 0 and not allow_fail:
        raise SubprocessError("** Failed: " + to_quoted_string(args))
    # return
    if stdout and allow_fail: return (status, output)
    elif stdout:              return output
    else:                     return status


## @}
# end of Doxygen group