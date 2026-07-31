import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import path from 'path'
import mathjax3 from 'markdown-it-mathjax3'

// https://vitepress.dev/reference/site-config

// IMPORTANT:
// DocumenterVitepress *rewrites this file* at build time. In particular it replaces:
// - `base: 'REPLACE_ME_DOCUMENTER_VITEPRESS'` with the correct base for each deployed version
//   (e.g. `/Sindbad.jl/dev/`, `/Sindbad.jl/stable/`, `/Sindbad.jl/v0.1.0/`).
// - `REPLACE_ME_DOCUMENTER_VITEPRESS_DEPLOY_ABSPATH` with the repository absolute base (e.g. `/Sindbad.jl`).
//
// To keep our custom sidebar/nav, we still need to preserve the placeholder strings that
// DocumenterVitepress expects to find.
function getBaseRepository(base: string): string {
  if (!base || base === '/') return '/'
  const parts = base.split('/').filter(Boolean)
  return parts.length > 0 ? `/${parts[0]}/` : '/'
}

const baseTemp = {
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
}

const conceptItems = [
  { text: 'SINDBAD', link: '/pages/concept/overview' },
  { text: 'Experiment', link: '/pages/concept/experiment' },
  { text: 'TEM', link: '/pages/concept/TEM' },
  { text: 'info', link: '/pages/concept/info' },
  { text: 'land', link: '/pages/concept/land' },
]

const settingsItems = [
  { text: 'Overview', link: '/pages/settings/overview' },
  { text: 'Experiments', link: '/pages/settings/experiment' },
  { text: 'Forcing', link: '/pages/settings/forcing' },
  { text: 'Models', link: '/pages/settings/model_structure' },
  { text: 'ParameterOptimization', link: '/pages/settings/optimization' },
  { text: 'Parameters', link: '/pages/settings/parameters' },
]

// "Code" is the generated API reference (from Documenter + generators).
//
// Important: Vitepress top-nav dropdowns don't expand nested groups more than one level.
// For good UX:
// - top nav shows *direct* entry points (TEM / Modules / Extensions)
// - sidebar provides the detailed tree and makes section headings clickable
const codeItemsNav = [
  { text: 'Sindbad', link: '/pages/code/api/Sindbad' },
  // TEM should land on the package/module docstring page
  { text: 'TEM', link: '/pages/code/api/SindbadTEM' },
  // Modules should land on an index page
  { text: 'Modules', link: '/pages/code/api/modules/index' },
  // Extensions should land on the extensions index
  { text: 'Extensions', link: '/pages/code/api/extensions/index' },
]

const codeItemsSidebar = [
  { text: 'Sindbad', link: '/pages/code/api/Sindbad' },
  {
    text: 'TEM',
    link: '/pages/code/api/SindbadTEM',
    items: [
      { text: 'Processes', link: '/pages/code/api/SindbadTEM.Processes' },
      { text: 'Utils', link: '/pages/code/api/SindbadTEM.Utils' },
      { text: 'TEMTypes', link: '/pages/code/api/SindbadTEM.TEMTypes' },
      { text: 'Variables', link: '/pages/code/api/SindbadTEM.Variables' },
    ],
  },
  {
    text: 'Modules',
    link: '/pages/code/api/modules/index',
    items: [
      { text: 'Types', link: '/pages/code/api/Types' },
      { text: 'Setup', link: '/pages/code/api/Setup' },
      { text: 'DataLoaders', link: '/pages/code/api/DataLoaders' },
      { text: 'Simulation', link: '/pages/code/api/Simulation' },
      { text: 'ParameterOptimization', link: '/pages/code/api/ParameterOptimization' },
      { text: 'MachineLearning', link: '/pages/code/api/MachineLearning' },
      { text: 'Visualization', link: '/pages/code/api/Visualization' },
      { text: 'Experiment', link: '/pages/code/api/Experiment' },
    ],
  },
  {
    text: 'Extensions',
    link: '/pages/code/api/extensions/index',
    items: [
      { text: 'Extensions (index)', link: '/pages/code/api/extensions/index' },
      { text: 'SindbadCMAEvolutionStrategyExt', link: '/pages/code/api/extensions/SindbadCMAEvolutionStrategyExt' },
      { text: 'SindbadDifferentialEquationsExt', link: '/pages/code/api/extensions/SindbadDifferentialEquationsExt' },
      { text: 'SindbadEnzymeExt', link: '/pages/code/api/extensions/SindbadEnzymeExt' },
      { text: 'SindbadFiniteDiffExt', link: '/pages/code/api/extensions/SindbadFiniteDiffExt' },
      { text: 'SindbadFiniteDifferencesExt', link: '/pages/code/api/extensions/SindbadFiniteDifferencesExt' },
      { text: 'SindbadFluxExt', link: '/pages/code/api/extensions/SindbadFluxExt' },
      { text: 'SindbadForwardDiffExt', link: '/pages/code/api/extensions/SindbadForwardDiffExt' },
      { text: 'SindbadLuxExt', link: '/pages/code/api/extensions/SindbadLuxExt' },
      { text: 'SindbadNLsolveExt', link: '/pages/code/api/extensions/SindbadNLsolveExt' },
      { text: 'SindbadOptimisersExt', link: '/pages/code/api/extensions/SindbadOptimisersExt' },
      { text: 'SindbadOptimizationExt', link: '/pages/code/api/extensions/SindbadOptimizationExt' },
      { text: 'SindbadPlotsExt', link: '/pages/code/api/extensions/SindbadPlotsExt' },
      { text: 'SindbadPolyesterForwardDiffExt', link: '/pages/code/api/extensions/SindbadPolyesterForwardDiffExt' },
      { text: 'SindbadPreallocationToolsExt', link: '/pages/code/api/extensions/SindbadPreallocationToolsExt' },
      { text: 'SindbadZygoteExt', link: '/pages/code/api/extensions/SindbadZygoteExt' },
    ],
  },
]
const aboutItems = [
  { text: 'Contact', link: '/pages/about/contact' },
  { text: 'License', link: '/pages/about/license' },
  { text: 'Publications', link: '/pages/about/publications' },
  { text: 'Support', link: '/pages/about/support' },
  { text: 'Team', link: '/pages/about/team' },
]

const manualItems = [
  { text: 'Overview', link: '/pages/develop/overview' },
  { text: 'Install', link: '/pages/develop/install' },
  { text: 'Modeling Convention', link: '/pages/develop/conventions' },
  { text: 'Model/Approach', link: '/pages/develop/model_approach' },
  { text: 'Sindbad Types', link: '/pages/develop/sindbad_types' },
  { text: 'Array Handling', link: '/pages/develop/array_handling' },
  { text: 'Land Utils', link: '/pages/develop/land_utils' },
  { text: 'Experiments', link: '/pages/develop/experiments' },
  { text: 'Experiment Outputs', link: '/pages/develop/sindbad_outputs' },
  { text: 'Spinup', link: '/pages/develop/spinup' },
  { text: 'Hybrid ML', link: '/pages/develop/hybrid_modeling' },
  { text: 'ParameterOptimization Methods', link: '/pages/develop/optimization_method' },
  { text: 'Cost Metrics', link: '/pages/develop/cost_metrics' },
  { text: 'Cost Function', link: '/pages/develop/cost_function' },
  { text: 'Documentation', link: '/pages/develop/how_to_doc' },
  { text: 'Useful Helpers', link: '/pages/develop/helpers' },
]

const navTemp = {
  nav: [
    { text: 'Concept', items: conceptItems,
    },
    { text: 'Settings',  items: settingsItems, 
    },
    { text: 'Code', 
      items: codeItemsNav,
    },
    { text: 'Develop', items: manualItems,
    },
    { text: 'About', 
      items: aboutItems
    },
  ],
}

const nav = [
  ...navTemp.nav,
  {
    component: 'VersionPicker',
  }
]

const sidebar = [
  { text: 'Concept', items: conceptItems,
  },
    { text: 'Develop', items: manualItems,
  },
  { text: 'Settings',  items: settingsItems,
  },
  { text: 'Code',
    collapsed: true,
    items: codeItemsSidebar
  },
  { text: 'About',
    items: aboutItems
  },
]

export default defineConfig({
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  title: "SINDBAD",
  description: "A model-data integration framework for terrestrial ecosystem processes",
  lastUpdated: true,
  cleanUrls: false,
  ignoreDeadLinks: true,
  outDir: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  
  head: [
    // IMPORTANT: Vitepress does not automatically prefix `head` hrefs with `base`.
    // Let DocumenterVitepress inject the correct base-dependent favicon path.
    ['link', { rel: 'icon', href: 'REPLACE_ME_DOCUMENTER_VITEPRESS_FAVICON' }],
    // Required by DocumenterVitepress' VersionPicker component.
    ['script', { src: `${getBaseRepository(baseTemp.base)}versions.js` }],
    ['script', { src: `${baseTemp.base}siteinfo.js` }],
    ['script', {}, `
      window.MathJax = {
        tex: {
          inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
          displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']],
        },
        options: {
          skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code']
        },
        startup: {
          ready: () => {
            MathJax.startup.defaultReady();
            MathJax.startup.promise.then(() => {
              if (MathJax.typesetPromise) {
                MathJax.typesetPromise();
              }
            });
          }
        }
      };
    `],
    ['script', { 
      type: 'text/javascript',
      id: 'MathJax-script',
      // Vitepress `head` attrs are typed as string values.
      async: 'true',
      src: 'https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'
    }],
  ],
  
  vite: {
    define: {
      __DEPLOY_ABSPATH__: JSON.stringify('REPLACE_ME_DOCUMENTER_VITEPRESS_DEPLOY_ABSPATH'),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '../components')
      }
    },
    build: {
      assetsInlineLimit: 0, // so we can tell whether we have created inlined images or not, we don't let vite inline them
    },
    optimizeDeps: {
      exclude: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities/client',
        'vitepress',
        '@nolebase/ui',
      ], 
    }, 
    ssr: { 
      noExternal: [ 
        // If there are other packages that need to be processed by Vite, you can add them here.
        '@nolebase/vitepress-plugin-enhanced-readabilities',
        '@nolebase/ui',
      ], 
    },
  },

  markdown: {
    math: true,
    config(md) {
      md.use(tabsMarkdownPlugin)
      md.use(mathjax3)
    },
    theme: {
      light: "github-light",
      dark: "github-dark"}
  },

  themeConfig: {
    outline: 'deep',
    logo: { src: '/sindbad_logo.png', width: 24, height: 24 },
    search: {
          provider: 'local',
          options: {
            detailedView: true
          }
        },

    nav: nav,
    sidebar: sidebar,
    socialLinks: [
      {
        icon: "github",
        link: 'https://github.com/LandEcosystems/Sindbad',
        // You can include a custom label for accessibility too (optional but recommended):
        ariaLabel: 'repo address'
      },
    ],
    footer: {
      // IMPORTANT: `footer.message` is raw HTML (no withBase), so we must include the correct base prefix.
      message: `<a href="https://www.bgc-jena.mpg.de/en" target="_blank" rel="noopener"><img src="${baseTemp.base}logo_mpi_grey.png" class="footer-logo" alt="MPI Logo"/></a>`,
      copyright: '© Copyright 2025 <strong> SINDBAD Development Team</strong></span>'
    }
  }
})
