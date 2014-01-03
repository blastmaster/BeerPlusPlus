use Test::More;

# skipping test if Test::Pod is not available
eval "use Test::Pod";
plan skip_all => "Test::Pod is required for testing pod" if $@;

all_pod_files_ok();
