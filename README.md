# Rails8 Template
This template sets up a new Rails 8 application with some default functionality already setup.

## Default features
- Authenticated Grape API with Grape entities.
- Swagger documentation available at `/api-docs` URL (in development only).
- User registration and login.
- User profile.

## How to use

```
rails new someAppName --api --devcontainer -m /path/to/rails8-template/grape_api_template.rb
```

E.G

```
rails new someAppName --api --devcontainer -m /Users/jonathanmeaney/Development/rails/rails8-template/grape_api_template.rb
```

## devcontainer.json
If using `devcontainer` then the following customization is useful for Ruby and Rails development!

```json
"customizations": {
  "vscode": {
    "extensions": [
      "ms-azuretools.vscode-docker",
      "shopify.ruby-lsp",
      "misogi.ruby-rubocop",
      "shopify.ruby-extensions-pack",
      "esbenp.prettier-vscode",
      "fvclaus.sort-json-array"
    ],
    "settings": {
      "ruby.lint": {
        "rubocop": {
          "lint": true
        }
      },
      "ruby.format": "rubocop",
      "ruby.rubocop.executePath": "/home/vscode/.rbenv/shims/",
      "files.associations": {
        "Gemfile": "ruby"
      },
      "[ruby]": {
        "editor.defaultFormatter": "misogi.ruby-rubocop",
        "editor.formatOnSave": true
      },
      "[yaml, yml]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
      },
      "prettier": {
        "configPath": "prettierrc.yaml"
      }
    }
  }
}
```
