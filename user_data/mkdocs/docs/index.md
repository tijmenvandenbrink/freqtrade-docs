# Welcome to Freqtrade backtest docs

## Commands

* `make init` - Initializes the mkdocs directories
* `make backtest --config $(config) --strategy $(strategy) --timerange $(timerange) -i $(timeframe)` - Runs the backtest
* `make context` - Generates a context file which stores neccesary information. This step run automatically after running `make backtest`.
* `make plot-profit` - Creates the plot-profit html file
* `make plot-dataframe` - Creates the plot-dataframe html file(s)
* `make keep` - Stores the results of your latest backtest in the `docs/backtests` directory
* `make docs` - Renders the results of your latest backtest into a markdown file

## Mkdocs specific commands
* `mkdocs new [dir-name]` - Create a new project.
* `mkdocs serve` - Start the live-reloading docs server.
* `mkdocs build` - Build the documentation site.
* `mkdocs -h` - Print help message and exit.

## Project layout

    Makefile    # The commands file
    user_data/
        mkdocs/       
            mkdocs.yml              # The configuration file.
            generate_markdown.py    # Generated the markdown files from the latest backtest
            docs/
                index.md            # The documentation homepage.
                backtests/
                    2022-07-08_05-28-47 # Backtest results per directory
            templates/ # Here are the markdown templates stored

## Overview of all backtest results