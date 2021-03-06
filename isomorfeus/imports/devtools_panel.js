// entry file for the browser environment
// import stylesheets here
import '../styles/application.css';

// import npm modules that are valid to use only in the browser
import * as Redux from 'redux';
global.Redux = Redux;
import React from 'react';
global.React = React;
import ReactDOM from 'react-dom';
global.ReactDOM = ReactDOM;

import * as Mui from '@material-ui/core'
import * as MuiStyles from '@material-ui/styles'
import * as MuiLab from '@material-ui/lab'
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';
import ChevronRightIcon from '@material-ui/icons/ChevronRight';
global.Mui = Mui;
global.MuiStyles = MuiStyles;
global.MuiLab = MuiLab
global.ExpandMoreIcon = ExpandMoreIcon;
global.ChevronRightIcon = ChevronRightIcon;
chrome.runtime.onConnect.addListener(function(port) {});
global.BackgroundConnection = chrome.runtime.connect({name: "opal-devtools-panel"});

import init_app from 'devtools_panel_loader.rb';
init_app();
Opal.load('devtools_panel_loader');


