First timer here.
Taking part in LD is an awesome experience.
Always had trouble getting things done but the 48 hours limit forced me this time and I am amazed how much I can do in very short time if I have to.
I have three small children and bunch of real life stuff to do all the time and I expected to have no more net dev time than half of it which was a good estimation as according to my timelapse video I had spent about 26 hours with the game of which about three and a half was wasted working on my initial concept and engine which then I changed to the one which **[GOLKIA](https://ldjam.com/events/ludum-dare/46/golkia)** get built upon: **A game of life simulation sandbox**.

I started with Corona SDK which seemed promising, I saw a talk by John Romero who suggested it, coding is done in Lua which I get used to with LOVE and PICO-8 before and I tried to give it a shot until I realized that it has no game loop in its classic form and yet it can get forced to work like that it seemed too messy to go into it as I wanted to get to actual game development.
Also, I have to discard my original concept. During the theme voting final I figured out a concept for every possible themes and up and downwoted accordingly.
For *Keep it alive** i had the following note: *Life automata with aging cells**.

At the start I looked on this note and it was far from enough to start with.
This was a lession to the future that the concepts should be made to the point I can develop the game immediately after the start.
Yet I changed in time. I remembered that Conway died in the COVID-19 epidemic and I thought there is no better time to make a hommage to him than now.
Initially I planned to gave it a twist with more states, some being power sources and others being different kind of live forms like [domains](https://en.wikipedia.org/wiki/Domain_(biology)).

However I fist needed an effective Game of Life simulation, once that is done, the states are not too hard to apply later.
I then came to the idea of making the video card to evaluate the game.
Before this game, I only made a shader which applied certain palettes on the whole game screen.
This was different but I switched to the engine I made that before: LOVE.

My productivity got boosted and soon I ended up a shader applied to a 8bit grayscale depth canvas (there was no 1bit option) and the end result being copied to another one which is shown to the user.
Effectively the whole game is running on that low-res image.
After resolved multiple issues, it worked like a charm, on high FPS without lags.

My development machine is a 2011 made IBM Thinkpad T420.
I attached a 2560x1440 monitor onto it which really pushes its video card to its limits and I usually have to play games windowed.
Now in the play+rate period, I see many trivial and plain games to get laggy and unplayable slow on this machine, most of them are made with Unity.
But this was different as it runned perfectly on full screen.
This is the reason I like to develop on weak computers: It assures that the users will not have performance issues.

Drawing on the live evaluated Game of Life world was really satisfying and I was glad that the game was good enough to apply.
Even my wife tried it and liked it which made me very happy as she do not play video games at all excluding some casual Sokoban, Match-3, or Tetris.

I had 3 hours left.
I rapidly applied the pause/resume and reset features and changed the borders from continous to fixed, all of these were trivial changes and gave a lot to the experience. I made a quick list of possible features and ordered them by importance: zoom/pan; speedup/down; increase/decrease brush size.
Went for the zoom which the game really deserved and with all my efforts I tried to make it work but I failed and had to publish the game without that feature.
**My mistake was that I want it to work perfectly instead of decently.**
As the mouse pointer is also a painter tool, I wanted to keep it above the same position while zooming.
I could definiately get the zoom feature done in time without this and it would be fine enough together with panning.
The post compo version works like intended but I had to think on it for a long time.

So, it was deadline and I published the game without the ability to zoom.
But hey, it was a very good feeling as I really liked the game!

Golly, which is the most feature heavy Game of Life software stops while you draw, although it can handle very huge GOL constructs without problem.
I do not stress tested [GOLKIA](https://ldjam.com/events/ludum-dare/46/golkia) but I assume it would be also fine with much bigger maps as well.
Still, it is more a children tool than Golkia
