# Mirarr

![Screenshot_2024-07-14-21-26-49_1920x1080](https://github.com/user-attachments/assets/1a54e640-0972-4fd7-87d2-29eb8780b80e)
![Screenshot_2024-07-14-21-27-11_1920x1080](https://github.com/user-attachments/assets/b9850d12-3c41-4e03-9228-939b3877324a)

## Watch movies and Arr.

### Available on Android, Windows, Linux and IOS.

This is a movie app that aims to simplify the process of watching movies and tv shows.

### Features

- Trending movies and TV shows
- Watchlist, Favorites and Rating
- Feed of released movies and TV shows.
- External links to movies and tv shows to watch.

### Download

Head over to the [releases](https://github.com/mirarr-app/mirarr/releases) page.
Download Apk for android.
Download mirarr-windows.zip for Windows.
Download mirrar.zip for Linux.
Download mirrar.ipa for sideloading on IOS.

#### Do I need to login?

No you don't have to. But the login process enables extra features like watchlist, favorties and rating which are all handled with TMDB.

#### Privacy concerns

- Of course the app is fully open source and always built from github actions.
- The optional login process is handled with TMDB and no information is logged anywhere else.

#### Build it yourself

First of all have [flutter]([https://docs.flutter.dev/get-started/install) installed and configured on your machine.

The current required versions are:
| Software | Versions |
|----------|----------|
| Dart SDK | >=3.1.0 <4.0.0 |

##### Clone the Repository

Clone this repository and change your directory to the cloned location:

```sh
git clone https://github.com/mirarr-app/mirarr.git
cd mirarr
```

##### Set Up Environment Variables

Get your `tmdb_api_key`, `tmdb_api_read`, and `omdb_api_key` and place them in a `.env` file in the root of the project. The compiled app will not run if the `.env` file was empty during compile time.

You can use the provided `dot_env.example` file as a template:

1. Create a `.env` file.

2. Open the `.env` file in a text editor and add your API keys:

   ```env
   TMDB_API_KEY=your_tmdb_api_key_here
   TMDB_API_READ=your_tmdb_api_read_here
   OMDB_API_KEY=your_omdb_api_key_here
   ```

##### Build

Run the following command to install the required dependencies:

```sh
flutter pub get
```

###### Build for Linux

To build the project for Linux, use the command:

```sh
flutter build linux
```

###### Build for Android (Debug)

To build the project for Android in debug mode, use the command:

```sh
flutter build android --debug
```

###### Build for Windows

To build the project for Windows, use the command:

```sh
flutter build windows
```

#### Special thanks

- [TMDB](https://www.themoviedb.org/) for their great free, open source API.
- [OMDB](http://www.omdbapi.com/) for their mostly free API.
- [scnsrc](https://scnsrc.me/) for their great RSS feed of released movies.
- External resources who we refer to when playing movies/tv shows.
