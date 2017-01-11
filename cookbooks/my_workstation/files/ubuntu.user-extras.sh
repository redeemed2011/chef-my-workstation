#!/usr/bin/env bash

gconftool-2 --set /apps/metacity/general/button_layout --type string "close,minimize,maximize:"

umake ide sublime-text
umake ide visual-studio-code
