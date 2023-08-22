# LiteList

A lightweight, mobile-friendly todo/action list, built using Vue 3 in the front-end, and D / Handy-Httpd in the back-end.

## App

The web application is a simple Vue 3 application, using the vue router and typescript, but few, if any, additional dependencies. The app is designed to be easy to use and accessible for mobile device users, instead of having to deploy a separate app for various devices.

The app starts with a basic login page, then directs authenticated users to a `/lists` page showing all of their lists. You can click on a list to view any notes that have been added to that list.

Run the app:
```shell
cd litelist-app
npm install
npm run dev
```

## API

The back-end API is a simple HTTP server built using [Handy-Httpd](https://github.com/andrewlalis/handy-httpd). It handles authentication, as well as the actual application data.

Run the API:
```shell
cd litelist-api
dub run
```

### Authentication

Users are authenticated by sending their credentials (username and password) and receiving a JWT access token that's valid for a short time period. Users can renew their access token if they still have a valid one, but once it expires, they'll need to log in again.

### Data

Application data is stored in a `users/` directory, relative to the `litelist-api` application's working directory. Inside `users/`, there's a directory for each username. Within each username directory, you'll find a `user.json` file with the user's information, as well as `notes.sqlite`, which is the SQLite3 database storing the user's notes.

## Building and Deploying

Because I deploy this application to [litelist.andrewlalis.com](https://litelist.andrewlalis.com), I've included a script `deploy.sh` and SystemD unit file `litelist-api.service` for convenience. If you're deploying somewhere else, you'll need to tweak those two files a bit.

Also note that in `deploy.sh` when building the API, I use a locally-referenced LDC2 compiler for D instead of the default DMD. This helps to improve performance, but leads to longer build times.
