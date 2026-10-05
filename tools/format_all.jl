using JuliaFormatter

isempty(ARGS) && error("usage: julia format_all.jl <directory>")

format(
    ARGS[1],
    MinimalStyle(),
    margin=100,
    always_for_in=true,
    for_in_replacement="∈",
    format_docstrings=true,
    yas_style_nesting=true,
    import_to_using=true,
    remove_extra_newlines=true,
    trailing_comma=false
)
