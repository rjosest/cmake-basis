/**
 * @file  testdriver-after-test.inc
 * @brief Default implementation of test driver.
 *
 * This file is included in the test driver generated by the CMake command
 * <a href="http://www.cmake.org/cmake/help/cmake-2-8-docs.html#command:create_test_sourcelist">
 * create_test_sourcelist()</a> directly after the call to the test main function.
 * It performs regression testing if requested.
 *
 * This file is a modified version of the itkTestDriverBeforeTest.inc file
 * which is part of the TestKernel module of the ITK 4 project.
 *
 * Copyright (c) 2011 University of Pennsylvania.<br />
 * Copyright Insight Software Consortium.<br />
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0.txt
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contact: SBIA Group <sbia-software at uphs.upenn.edu>
 */

//int main(int, char*)
//{
    // #include <sbia/basis/testdriver-before-test.inc> -> try {
        // [...]

        // revert redirection of output
        if (oldcoutbuf) {
            cout.rdbuf(oldcoutbuf);
            redirectstream.close();
        }
        // perform regression tests of output image(s)
        if (result == 0) {
            if (!regression_tests.empty() && verbose.getValue() > 0) {
                cout << "Performing regression tests" << endl;
            }
            for (size_t i = 0; i < regression_tests.size(); i++) {
                const char* test_file     = regression_tests[i].test_file.c_str();
                const char* baseline_file = regression_tests[i].baseline_file.c_str();
                if (regression_tests[i].method == BINARY_DIFF) {
                    int status = binary_diff(test_file, baseline_file);
                    if (status == -1) {
                        cerr << "No test output file found given file path " << test_file << "!" << endl;
                        status = 1;
                    } else if (status == -2) {
                        cerr << "No baseline file found given file path " << baseline_file << "!" << endl;
                        status = 1;
                    } else if (status != 0) {
                        cerr << "Files " << test_file << " and " << baseline_file << " differ!" << endl;
                    }
                    result += status;
                } else if (regression_tests[i].method == DIFF_LINES) {
                    int status = text_diff_lines(test_file, baseline_file, regression_tests[i].max_number_of_differences);
                    if (status == -1) {
                        cerr << "No test output file found given file path " << test_file << "!" << endl;
                        status = 1;
                    } else if (status == -2) {
                        cerr << "No baseline file found given file path " << baseline_file << "!" << endl;
                        status = 1;
                    } else if (status != 0) {
                        cerr << "Files " << test_file << " and " << baseline_file << " differ by more than the allowed " << regression_tests[i].max_number_of_differences << " lines!" << endl;
                    }
                    result += status;
                } else if (regression_tests[i].method == COMPARE_IMAGES) {
                    vector<string> baseline_files = get_baseline_filenames(baseline_file);
                    string         bestmatch      = baseline_file;
                    int            beststatus     = numeric_limits<int>::max();
                    if (baseline_files.empty()) {
                        bestmatch += " not found";
                        cerr << "No baseline images found given file path " << baseline_file << "!" << endl;
                    } else {
                        for (size_t j = 0; j < baseline_files.size(); j++) {
                            int status = image_regression_test(
                                    test_file,
                                    baseline_files[j].c_str(),
                                    regression_tests[i].intensity_tolerance,
                                    regression_tests[i].max_number_of_differences,
                                    regression_tests[i].tolerance_radius,
                                    regression_tests[i].orientation_insensitive);
                            if (status < beststatus) {
                                bestmatch  = baseline_files[j];
                                beststatus = status;
                            }
                            if (beststatus == 0) {
                                // perfect test result
                                break;
                            }
                        }
                        // if the best we can do still has errors...
                        if (beststatus != 0) {
                            image_regression_test(
                                    test_file,
                                    baseline_files[0].c_str(),
                                    regression_tests[i].intensity_tolerance,
                                    regression_tests[i].max_number_of_differences,
                                    regression_tests[i].tolerance_radius,
                                    regression_tests[i].orientation_insensitive,
                                    1); // ...generate error images
                        }
                    }
                    // output the matching baseline for submission to the dashboard
                    cout << "<DartMeasurement name=\"BaselineImageName\" type=\"text/string\">";
                    cout << os::path::basename(bestmatch);
                    cout << "</DartMeasurement>" << std::endl;
                    result += beststatus;
                } else {
                    cerr << "Invalid test method: " << regression_tests[i].method << "! Check testdriver implementation." << endl;
                }
            }
            // empty current working directory
            if (clean_cwd_after_test.getValue()) {
                os::emptydir(os::getcwd().c_str());
            }
        }

    // catch any exceptions
    } catch (const exception& e) {
        cerr << "Test driver caught an exception:\n";
        cerr << e.what() << "\n";
        result = -1;
    } catch (...) {
        cerr << "Test driver caught an unknown exception!!!\n";
        result = -1;
    }
//} end of main()