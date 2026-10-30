{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "markdown2html-converter";
  version = "1.1.12";

  src = fetchFromGitHub {
    owner = "magiclen";
    repo = "markdown2html-converter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-C35TCmcskhK3sHbkUp3kEaTA4P7Ls5Rn6ahUbzy7KXY=";
  };

  crateDeps = [
    "anyhow@1"
    "clap@4:derive"
    "comrak@0.19!"
    "concat-with@0.2"
    "html-escape@0.2"
    "html-minifier@4"
    "lazy-static-include@3"
    "terminal_size@0.3"
  ];

  meta = {
    changelog = "https://github.com/magiclen/markdown2html-converter/releases/tag/v${finalAttrs.version}";
    description = "Tool for converting a Markdown file to a single HTML file with built-in CSS and JS";
    homepage = "https://github.com/magiclen/markdown2html-converter";
    license = lib.licenses.mit;
    mainProgram = "markdown2html-converter";
    maintainers = with lib.maintainers; [ tomasajt ];
  };
})
