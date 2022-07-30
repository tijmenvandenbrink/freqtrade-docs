.EXPORT_ALL_VARIABLES:
LATEST_BACKTEST = $(shell cat $(USER_DATA_DIR)/backtest_results/.last_result.json | jq -r .latest_backtest)
STRATEGY_FROM_LATEST_BACKTEST = $(shell cat user_data/backtest_results/$$(cat user_data/backtest_results/.last_result.json | jq -r .latest_backtest) | jq -r '.strategy | to_entries[] | .key')
ID = $(shell echo $(LATEST_BACKTEST) | sed 's/.*result-//g' | awk -F. '{print $$1}')
USER_DATA_DIR := ./user_data
KEEP_DIR := ./user_data/mkdocs/docs/backtests

all: backtest plot-profit plot-dataframe keep docs

init:
	mkdir -p ${KEEP_DIR}

backtest: run-backtest context

run-backtest:
	@echo "Running backtest"
	docker-compose run --rm freqtrade backtesting --config $(config) --strategy $(strategy) --timerange $(timerange) -i $(timeframe) --cache none --breakdown month | tee $(USER_DATA_DIR)/plot/results.txt

plot-profit:
	@echo "Plotting profit diagram for $(ID)"
	docker-compose run --rm freqtrade plot-profit --timerange=$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep timerange | sed 's/.*timerange=//g') --timeframe=$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep timeframe | sed 's/.*timeframe=//g') --config=$(USER_DATA_DIR)/$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep config_file | sed 's/.*config_file=//g') --export-filename=/freqtrade/user_data/backtest_results/$(LATEST_BACKTEST)
	mv -n $(USER_DATA_DIR)/plot/freqtrade-profit-plot.html $(USER_DATA_DIR)/plot/$(ID)-freqtrade-profit-plot.html

plot-dataframe:
	@echo "Plotting dataframes for $(ID)"
	docker-compose run --rm freqtrade plot-dataframe --strategy ${STRATEGY_FROM_LATEST_BACKTEST} --timerange=$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep timerange | sed 's/.*timerange=//g') --timeframe=$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep timeframe | sed 's/.*timeframe=//g') --config=$(USER_DATA_DIR)/$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep config_file | sed 's/.*config_file=//g') --export-filename=/freqtrade/user_data/backtest_results/$(LATEST_BACKTEST)
	for filename in $(USER_DATA_DIR)/plot/freqtrade-plot-*.html; do newfilename=`echo "$${filename}" | sed "s/.html/-${ID}.html/g"`; mv -v $${filename} $${newfilename}; done

context:
	@echo "Generating context-${ID}"
	echo "id=$(ID)" > $(USER_DATA_DIR)/plot/context-${ID}.txt
	echo "config_file=$(shell basename $(config))" >> $(USER_DATA_DIR)/plot/context-${ID}.txt
	echo "strategy_file=$(strategy).py" >> $(USER_DATA_DIR)/plot/context-${ID}.txt
	echo "timerange=$(timerange)" >> $(USER_DATA_DIR)/plot/context-${ID}.txt
	echo "timeframe=$(timeframe)" >> $(USER_DATA_DIR)/plot/context-${ID}.txt
	echo "results_file=results-$(ID).txt" >> $(USER_DATA_DIR)/plot/context-${ID}.txt
	if test -f "$(USER_DATA_DIR)/strategies/$(strategy).json"; then echo "parameters_file=$(strategy).json" >> $(USER_DATA_DIR)/plot/context-${ID}.txt; fi

keep:
	@echo "Keeping results for $(ID)"

	@echo "Renaming results.txt"
	-mv -n $(USER_DATA_DIR)/plot/results.txt $(USER_DATA_DIR)/plot/results-$(ID).txt

	@echo "Create target directory"
	mkdir -p $(KEEP_DIR)/$(ID)

	@echo "Move plot files"
	-mv -n $(USER_DATA_DIR)/plot/*$(ID)*.html $(KEEP_DIR)/$(ID)/

	@echo "Copy results file to target directory"
	-cp $(USER_DATA_DIR)/plot/results-$(ID).txt $(KEEP_DIR)/$(ID)/

	@echo "Copy backtest files to target directory"
	-cp $(USER_DATA_DIR)/backtest_results/*$(ID).* $(KEEP_DIR)/$(ID)/

ifeq ($(strip $(STRATEGY_FROM_LATEST_BACKTEST)),)
	@echo "We couldn't determine the Strategy from the backtest file. Exitting"
	false
endif

	@echo "Copy strategy files to target directory"
	-cp $(USER_DATA_DIR)/strategies/$(STRATEGY_FROM_LATEST_BACKTEST).* $(KEEP_DIR)/$(ID)/

	@echo "Copy config to target directory"
	-cp $(USER_DATA_DIR)/$(shell cat $(USER_DATA_DIR)/plot/context-${ID}.txt | grep config_file | sed 's/.*config_file=//g') $(KEEP_DIR)/$(ID)/

	@echo "Copy context to target directory"
	-cp $(USER_DATA_DIR)/plot/context-${ID}.txt $(KEEP_DIR)/$(ID)/

docs:
	@echo "Generating docs for ${ID}"
	./$(USER_DATA_DIR)/mkdocs/generate_markdown.py ./$(USER_DATA_DIR)/mkdocs/docs/backtests/$(ID) --strategy=$(STRATEGY_FROM_LATEST_BACKTEST) --id=$(ID)