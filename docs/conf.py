# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

import os
import sys

# Add the parent directory to the path so Sphinx can find the modules
sys.path.insert(0, os.path.abspath('..'))

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'SETAP-B'
release = '1.0.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.napoleon',
    'sphinx.ext.intersphinx',
    'sphinx.ext.viewcode',
    'myst_parser',
]

# MyST (Markedly Structured Text) configuration for Markdown support
myst_enable_extensions = ["colon_fence", "dollarmath"]
myst_url_schemes = ("http", "https", "ftp")

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'pydata_sphinx_theme'
html_static_path = ['_static']
html_title = 'SETAP-B Documentation'

# Theme options
html_theme_options = {
    "logo": {
        "text": "SETAP-B",
    },
    "github_url": "https://github.com/lula1450/SETAP-B",
    "twitter_url": "https://twitter.com",
}

# -- Options for autodoc ----------------------------------------------------
autodoc_member_order = 'bysource'
autodoc_typehints = 'description'
