using Pkg

# Make docs builds reproducible by isolating the load path from the user's global env.
# This prevents unrelated packages in `@v#.#` (e.g. different Zygote versions) from
# activating Sindbad extensions and/or causing resolution conflicts.
empty!(Base.LOAD_PATH)
push!(Base.LOAD_PATH, "@")
push!(Base.LOAD_PATH, "@stdlib")

cd(@__DIR__)
Pkg.activate(".")

# Ecosystem dependencies are registered; instantiate normally.
Pkg.instantiate()
Pkg.precompile()

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
    clean=true,
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/LandEcosystems/Sindbad.jl",
        # IMPORTANT:
        # We intentionally skip the internal VitePress build during `makedocs`.
        # DocumenterVitepress emits `build/.documenter/index.md` from Documenter markdown,
        # which mangles YAML frontmatter (required for `layout: home`) into plain text.
        # We overwrite `build/.documenter/index.md` with the raw VitePress home page and
        # then run a single VitePress build *afterwards*, so the deployed HTML uses the
        # correct homepage layout.
        build_vitepress = false,
    ),
    remotes=nothing,
    draft=false,
    warnonly=true,
    source="src",
    build="build",
    )

# VitePress "home" pages rely on YAML frontmatter, but DocumenterVitepress' Markdown pipeline
# rewrites `src/index.md` (escaping/flattening YAML), which makes VitePress render the YAML
# as plain text. For local preview (`vitepress dev build/.documenter`) and for deployment,
# overwrite the generated entrypoint with the raw VitePress source.
documenter_src_dir = joinpath(@__DIR__, "build", ".documenter")
raw_vitepress_index = joinpath(@__DIR__, "src", "index.md")
generated_index = joinpath(documenter_src_dir, "index.md")
if isdir(documenter_src_dir) && isfile(raw_vitepress_index)
    cp(raw_vitepress_index, generated_index; force=true)
end

# Build the VitePress site (after we restored the homepage frontmatter).
#
# CI installs JS dependencies via the docs workflow (`npm ci` in `docs/`), and local dev
# already has `docs/node_modules` when running `npm run docs:dev` / `docs:build`.
DocumenterVitepress.build_docs(joinpath(@__DIR__, "build"); md_output_path = ".documenter")

final_site_dir = joinpath(@__DIR__,"build/final_site/")
if !isdir(final_site_dir)
    final_site_dir = joinpath(@__DIR__,"build/1/")
end

if !isdir(joinpath(final_site_dir, "/pages/concept/sindbad_info"))
    cp(joinpath(@__DIR__,"src/pages/concept/sindbad_info"), joinpath(final_site_dir, "pages/concept/sindbad_info"); force=true)
end

#
# Deployment
#
# Avoid attempting to deploy during local builds. Deploy explicitly by setting:
# - CI=true (typical in GitHub Actions), or
# - SINDBAD_DOCS_DEPLOY=true
#
should_deploy = get(ENV, "CI", "false") == "true" || get(ENV, "SINDBAD_DOCS_DEPLOY", "false") == "true"

if should_deploy
    DocumenterVitepress.deploydocs(; 
        repo = "github.com/LandEcosystems/Sindbad.jl", # this must be the full URL!
        target = joinpath(@__DIR__, "build"), # this is where Vitepress stores its output
        branch = "gh-pages",
        devbranch = "main",
        push_preview = true
    )
end
