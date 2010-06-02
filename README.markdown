
http://developer.getsprouted.com/downloads/
developer@journler.com

Only use this code if you are currently running the latest version of Journler, v2.5.5.
Be sure to back up your journal beforehand!

The JournlerCore project is divided into two sections:
	i. 	The JournlerCore framework itself
	ii. 	An application demonstrating its use, called JournlerCore Demonstration
	
Notice that both the framework and the application are linked against the SproutedUtilities and SproutedInterface frameworks. JournlerCore depends on these frameworks, but the Sprouted frameworks are not copied directly into JournlerCore. They are copied into the application along with the JournlerCore framework. This mirrors the setup in Journler itself.

JournlerCore is composed of three parts:
	i.	The Model
	ii.	Searching and Lexicon
	iii.	Utilities
	
The model manages the Journler data. Searching and Lexicon provide an API to higher levels which would like to search the data. Utilities include categories and some file watching utilities. The latter should probably be moved outside the core into the application level.

Journler itself is divided into three layers, each layer depending on the previous:
	i.	JournlerCore
	ii.	JournlerInterface
	iii.	Application Code
	
What you are seeing here is the JournlerCore. The JournlerInterface is the next level up and provides most of the user interface to the data. Application code handles application specific details such as the interface to preferences, the drop box and so on.

---

The code is a mess. In places it is poorly structured. It is poorly documented. It is at times not obvious why some functions must be called or what the relationship between methods is. In some cases it is necessary to call methods in a particular order or in particular groupings, but it is not indicated when.

Ultimately I would like all that changed. The goal is to produce a well documented, well structured, intuitive framework that 3rd party developers will be able to use to extend Journler's functionality. In fact developers could already begin extending Journler. This code provides complete access to a user's journal, folders (collections), entries, resources -- everything. Using this framework a developer could write a web interface to a user's journal or develop an iPhone application.

Feel free to fool around with the code. I would recommend that you test your own projects on a copy of your journal. Keep your original data safe! If you believe you have made or can make improvements to the code, I would love to see them. I have set up a separate email address for developer related inquiries. You can contact me at developer@journler.com.

Be sure not to make changes to your journal data while Journler is running. Notifications are not passed between instances of the framework and your data will end up out of sync.

---

More extensive documentation is forthcoming, following the doxygen format. I also plan to extend the demonstration's functionality in order to better indicate how 3rd party developers can take advantage of the framework.