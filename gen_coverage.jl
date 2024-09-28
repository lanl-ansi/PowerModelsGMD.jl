using Pkg, Coverage
Pkg.test("PowerModelsGMD", coverage=true)
cov = generate_coverage()
LCOV.writefile("coverage-lcov.info", cov)

