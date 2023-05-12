#!/usr/bin/env node

const chalk = require('chalk');
const clear = require('clear');
const figlet = require('figlet');
const path = require('path');
const program = require('commander');


clear();
console.log(
  chalk.red(
    figlet.textSync('batcher bot', { horizontalLayout: 'full' })
  )
);

program
  .version('0.0.1')
  .description("Batcher Liquidity Bot CLI")
  .option('-l, --liquiditytype', 'Either jit (just in time) or always (always-on)')
  .parse(process.argv);

const options = program.opts();

console.log('you want to run liquidity with:');
if (options.liquiditytype) console.log('  - liquidity type');


if (!process.argv.slice(2).length) {
  program.outputHelp();
}
