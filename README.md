# RickTacMorty

## Tic Tac Toe with a fun twist - Built with Phoenix LiveView 🧡

## Table of Contents

- [Introduction](#introduction)
- [Demo](#demo)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Features](#features)
- [Todo](#todo)

## Introduction

### Goal

My target was to implement a Rick and Morty themed Tic Tac Toe game in which Mortys' would be human players and Ricks' would be unbeatable computer/ai players further more I wish to add different personas of Morty and Rick as AI players i.e Evil Morty(unbeatable ai) and Doofus Rick(random computer) that would give edge to Morty(human player).

Further, I think game can be extended by adding different persons to human players such introducitng persons such as Jerry who would give lucky move to players by either auto marking best move or making Rick make a mistake(computer picking random move instead of best move). Beth would make Rick make two random moves.

I got lot of inspiration and code 😅 from [fly-app-tic-tac-toe](https://github.com/fly-apps/tictac). However it did substantial modification to the code to get it working with the updated Phoenix LiveView stack and fashioned it according to my concept of the game.

## Demo

Visit: [https://rick-tac-morty.fly.dev](https://rick-tac-morty.fly.dev)

## Getting Started

### Prerequisites

Before you begin, ensure you have the following prerequisites:

- [Elixir](https://elixir-lang.org/install.html) (at least Elixir 1.12)
- [Phoenix Framework](https://hexdocs.pm/phoenix/installation.html)
- [PostgreSQL](https://www.postgresql.org/download/)

### Installation

1. Clone this repository to your local machine:

   ```bash
   git clone https://github.com/tlarevo/rick-tac-morty.git
   cd rick-tac-morty
   ```

2. Install dependancies:

   ```bash
   mix deps.get

   ```

3. Setup database:

   ```bash
    mix ecto.setup

   ```

4. Start the phoenix server:

   ```bash
    iex -S mix phx.server

   ```

## Features

- Realtime game play between two human players who could be anywhere in the world
  - Shareable game code for the secondary player to join
- Game play between Human vs Computer
- Better UX with Rick and Morty theme
- Winner celebration with confetti

## To Do

- [x] Human vs Human play
- [x] Human vs Computer/AI play
- [x] Added celebratory confetti on winner's screen
- [ ] Spectator mode
- [ ] Complete mixmax algorithm
- [ ] Better documentation
- [ ] Unit tests
- [ ] Further UX improvements
