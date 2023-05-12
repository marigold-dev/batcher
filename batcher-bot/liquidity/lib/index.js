#!/usr/bin/env node
"use strict";
var chalk = require('chalk');
var clear = require('clear');
var figlet = require('figlet');
var path = require('path');
var program = require('commander');
clear();
console.log(chalk.red(figlet.textSync('batcher-liquidity-bot', { horizontalLayout: 'full' })));
program
    .version('0.0.1')
    .description("Batcher Liquidity Bot CLI")
    .option('-l, --liquiditytype', 'Either jit (just in time) or always (always-on)')
    .parse(process.argv);
var options = program.opts();
console.log('you want to run liquidity with:');
if (options.liquiditytype)
    console.log('  - liquidity type');
if (!process.argv.slice(2).length) {
    program.outputHelp();
}
