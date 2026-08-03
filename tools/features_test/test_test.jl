using SindbadTEM, Test

test_model("cAllocation_Friedlingstein1999")              # what test-model checks for one/several changed approaches
test_model("cCycleDisturbance_WROASTED")

analyse_tem()                                        # what analyse-tem checks: full ~240-approach catalog, informational
test_tem()                                           # what test-tem checks: full timing/allocation benchmark + HTML report
