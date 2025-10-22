Screens: 
This is the folder where all the screens of an app usually goes. As it can be seen on the screenshot, each screen has its own folder. In this specific example the app has a Homescreen which uses a bottom navigation bar and 4 major screens (war, news, major_orders and game). I will discuss this part more later.

Widgets: 
This is the folder where all the reusable widgets of the app usually goes. In this folder I save files like my custom_scaffold and all the “recyclers” or list item widgets.

Services: 
This is basically all the external services used in the apps I make which is also known as my DIO folder. Classes here usually include connection to a REST API that feeds data to the app.

Models: 
Following the Services folder I always keep my Models (object classes) in a separated folder named Models. For people who used Flex or AIR in the past this used to be my ValueObjects folder. An example of a Model for dictionary terms:

Utils: 
This folder is the home of all “helper” files for external APIs or local libraries. Here I will keep things like firebase helper class, OneSignal helper class or even my own StringHelper class which includes functions to format Strings in our projects.

Styles: 
This is straight forward as it includes the themes and styles for the apps.

Commons.dart: 
This is a file we use as a main “import” for all the things used in the app. This way you just import a single file in your files which can also help with quick refactoring, changing or adding libraries.

https://medium.com/@kanellopoulos.leo/a-simple-way-to-organize-your-code-in-flutter-e175e7004fb5