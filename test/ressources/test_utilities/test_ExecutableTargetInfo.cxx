/**
 * @file  test_ExecutableTargetInfo.cxx
 * @brief Test ExecutableTargetInfo.cxx module.
 *
 * Copyright (c) 2011 University of Pennsylvania. All rights reserved.
 * See https://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
 *
 * Contact: SBIA Group <sbia-software at uphs.upenn.edu>
 */

#include <sbia/basis/test.h>      // unit testing framework
#include "ExecutableTargetInfo.h" // testee


using namespace SBIA_UTILITIESTEST_NAMESPACE;
using namespace std;

// ---------------------------------------------------------------------------
// Tests instance().
TEST(ExecutableTargetInfo, Instance)
{
    // get singleton instance
    const ExecutableTargetInfo* info = NULL;
    info = &ExecutableTargetInfo::instance();
    ASSERT_TRUE(info != NULL)
        << "Returned instance is NULL";
    // make sure that second call gives same instance
    ASSERT_EQ(info, &ExecutableTargetInfo::instance())
        << "Second call returned another instance";
}

// ---------------------------------------------------------------------------
// Tests get_target_uid().
TEST(ExecutableTargetInfo, GetTargetUID)
{
    const ExecutableTargetInfo& info = ExecutableTargetInfo::instance();
    EXPECT_STREQ("utilitiestest::basisproject.sh", info.get_target_uid("basisproject.sh").c_str())
        << "this project's namespace was not prepended to known target";
    EXPECT_STREQ("utilitiestest::unknown", info.get_target_uid("unknown").c_str())
        << "this project's namespace was not prepended to unknown target";
    EXPECT_STREQ(info.get_target_uid("helloworld").c_str(), info.get_target_uid("utilitiestest::helloworld").c_str ())
        << "using either target name or target UID does not give the same for own executable";
    EXPECT_STREQ("basis::basisproject.sh", info.get_target_uid("basis::basisproject.sh").c_str())
        << "UID changed";
    EXPECT_STREQ("hammer::hammer", info.get_target_uid("hammer::hammer").c_str())
        << "UID changed";
    EXPECT_STREQ("::hello", info.get_target_uid("::hello").c_str())
        << "namespace prepended even though global namespace specified";
    EXPECT_STREQ("", info.get_target_uid("").c_str())
        << "empty string resulted in non-empty string";
}

// ---------------------------------------------------------------------------
// Tests is_known_target().
TEST(ExecutableTargetInfo, IsKnownTarget)
{
    const ExecutableTargetInfo& info = ExecutableTargetInfo::instance();
    EXPECT_FALSE(info.is_known_target("basisproject.sh"))
        << "basisproject.sh is part of UtilitiesTest though it should not";
    EXPECT_TRUE(info.is_known_target("basis::basisproject.sh"))
        << "basis::basisproject.sh is not a known target";
    EXPECT_FALSE(info.is_known_target(""))
        << "empty target string is not identified as unknown target";
    EXPECT_FALSE(info.is_known_target("hammer::hammer"))
        << "some unknown target";
}

// ---------------------------------------------------------------------------
// Tests get_executable_name().
TEST(ExecutableTargetInfo, GetExecutableName)
{
    const ExecutableTargetInfo& info = ExecutableTargetInfo::instance();
#if WINDOWS
    EXPECT_STREQ("basisproject.sh", info.get_executable_name("basis::basisproject.sh").c_str())
#else
    EXPECT_STREQ("basisproject", info.get_executable_name("basis::basisproject.sh").c_str())
#endif
        << "name of basis::basisproject.sh executable is not basisproject(.sh)";
}

// ---------------------------------------------------------------------------
// Tests get_build_directory().
TEST(ExecutableTargetInfo, GetBuildDirectory)
{
    const ExecutableTargetInfo& info = ExecutableTargetInfo::instance();

    string dir;
    size_t idx;

    dir = info.get_build_directory("basis::basisproject.sh");
    cout << "Build directory of basis::basisproject.sh is '" << dir << "'" << endl;
    EXPECT_TRUE(dir != "") << "returned string is empty";
    EXPECT_NE(string::npos, idx = dir.rfind ("/"))
        << "returned directory does not contain a slash (/)";
    EXPECT_STREQ("/bin", dir.substr(idx).c_str())
        << "basis::basisproject.sh does not live in a 'bin' directory";

    EXPECT_STREQ("", info.get_build_directory("unknonw").c_str())
        << "returned value is not an empty string for unknown targets";
    EXPECT_STREQ ("", info.get_build_directory("").c_str())
        << "returned value is not an empty string for '' target";
}

// ---------------------------------------------------------------------------
// Tests get_installation_directory().
TEST(ExecutableTargetInfo, GetInstallationDirectory)
{
    const ExecutableTargetInfo& info = ExecutableTargetInfo::instance();

    string dir;

    dir = info.get_installation_directory("basis::basisproject.sh");
    cout << "Installation directory of basis::basisproject.sh is '" << dir << "'" << endl;
    EXPECT_TRUE(dir != "") << "returned string is empty";
    EXPECT_STREQ(dir.c_str(), info.get_build_directory("basis::basisproject.sh").c_str())
        << "build and installation directory are not the same for external executable";

    dir = info.get_installation_directory("helloworld");
    cout << "Installation directory of helloworld is '" << dir << "'" << endl;
    EXPECT_TRUE(dir != "") << "returned string is empty";
#if WINDOWS
    EXPECT_STREQ("C:/Program Files/SBIA/bin/utilitiestest", dir.c_str())
#else
    EXPECT_STREQ("/usr/local/bin/utilitiestest", dir.c_str())
#endif
        << "installation directory of helloworld is not the expected default";
    EXPECT_STRNE(dir.c_str(), info.get_build_directory("helloworld").c_str())
        << "build and installation directory are the same for own executable";

    EXPECT_STREQ("", info.get_installation_directory("unknown").c_str())
        << "returned value is not an empty string for unknown targets";
    EXPECT_STREQ("", info.get_installation_directory("").c_str())
        << "returned value is not an empty string for '' target";
}
