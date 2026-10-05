using Sindbad

using InteractiveUtils
using DocumenterVitepress
using Documenter
using DocStringExtensions

# Generate documentation files
include("gen_models_md.jl")
include("gen_lib_md.jl")
include("gen_ext_md.jl")

makedocs(; sitename="Sindbad",
    authors="Sindbad Development Team",
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/LandEcosystems/Sindbad.jl",
        devbranch = "main",
        devurl = "dev"
    ),
    draft=false,
    warnonly=true,
    source="src",
    build="build",
    )

DocumenterVitepress.deploydocs(;
    repo = "github.com/LandEcosystems/Sindbad.jl.git", # this must be the full URL!
    branch = "gh-pages",
    devbranch = "main",
    push_preview = false # don't push PR preview builds to gh-pages; still builds (and deploys) on push to main/tags
)