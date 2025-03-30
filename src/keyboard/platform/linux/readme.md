## Linux Layout

![current layout](./Images/layout.png)

- Your fingers naturally find their place on the highlighted keys.
- With the Wide Angle Mod, the right hand shifts one column over. Here's why it's great:
- Less strain on the right wrist.
- The layout becomes symmetrical.
- It's easier to reach Shift R + Level5 combination.
- The 8-layer layout necessitates three modifiers:
  1. Shift
  2. Level3, commonly known as Altgr
  3. Level5

```
include "level3(lalt_switch)" // Left Alt
include "level5(ralt_switch)" // Right Alt
```

- **Level5** is very obsure and extremely usefull to know about, if you wish to expand. It would
  allow for around 200 extra characters to be added.

### How 8 Layers works

Keyboard Layer Level:

1. No Modifiers
2. **Shift**.
3. **Level3**
4. **Level3 + Shift**
5. **Level5**
6. **Level5 + Shift**
7. **Level5 + Level3**
8. **Level5 + Level3 + Shift**

## How do you Type

### Numbers

![current layout](./Images/numbers.png)

- Accessed solely on **Layer3**
- A programmer who uses numbers often is a **bad programmer** see
  [https://en.wikipedia.org/wiki/Magic*number*%28programming%29A](https://en.wikipedia.org/wiki/Magic_number_%28programming%29)
  - This was why it was taken off the **Level1** (No modifiers)
  - For convenience, it is arranged in a number pad.
  - **1230**, constitude the most common numbers and hence are found on the home row.
  - The right hand number pad has close access to -+.,#%$\*/\\;:= , the most relevant mathematical operators.

## Alternative Characters (Requires Modifiers)

![current layout](./Images/alternativecharacters.png)

The least common alternative characters were delegated to **Level3** and **Level5** modifiers. They
were mapped with the followind reasoning.

- @ resembles Q
- & resembles B
- $ resembles Z
- × resembles X
- ~ resembles W
- ` is on C, "aCute"
- | is on V, "Vertical pipe"
- % is on M, "Modulus"
- # is on H, "Hash"
- < and > Easy Access for writing html etc.
- ^ is next to < and >
- - and - is next to the Numbers, with - easiest to access

## Alternative characters (No Modifiers required)

![current layout](./Images/alterntivecharacternom.png)

Generally the most common programming characters that you will type exist here:

- **? !** in the corner, because they typically close off sentences. Colemak was designed that letters that end sentences are more common on index and middle fingers, and placing it here on the pinky improves hand movement. ! also remains on its original position.
- **[ and ]** are easy access, because Regular Expressions tend to use them a lot. They mirror **) (**.
- **) (** are reversed because it is easier to roll the fingers from the pinky to the index finger. The following trigram is also very common: (); and works best in this orientation.
- **"** is on an easy access area, and mirrors '.
- **'** is on the opposite hand as s which is important for the 's bigram.
- **{ }** are usually automatically handled by editors, so they are placed in the hardest to reach region.
- **\*** and **/** are for the /\* bigram and are common vim commands.
- **\\** is on the right hand at the far corner, to resemble Escape and to work best with the following bigrams, \t \n \r
- **; : =** are all similar, and resemble Return. Again, because they exist near the corners, and they typically end sentences, they work best on the Pinky and Ring Fingers.
- **Prior Next aka Page Up Page Down** are directional keys in the middle. This is exceptionally useful on Thinkpad Keyboards, as they are right next to the Trackpoint. Even without the trackpoint, it is nice when it comes to just scrolling through documents. The reason why they are not the same as Page Up Page Down is to grant more flexibility for run configurations.
- **\_** the underscore here works well for writing object names, and works well with the m* and s* bigrams. It also is not a letter because that makes shifting it a painful exercise.

### Directional Keys

![current layout](./Images/directionalkeys.png)

- Inspired by Vim.
- Without the **Wide angle Mod**, the thumb will cramp up reaching for **level5**
- Amazing for editing regular documents.

### Letters

**Shift + [A-Z]**

![current layout](./Images/letters.png)

- **Capslock and Enter Removed** and replaced by **Shift**
- Shift's are replaced by **Control**
- Shift's are 3× more comfortable
- Control's are 5× more comfortable
- Capslock was not missed. Prefer it as Shift over Backspace or Escape provided that I have access to those keys on Level3 or Level5

### Return

![current layout](./Images/return.png)

- Placed on the o because in vim, its functionality is similar to Enter.
- Surprisingly, not a big issue. I would consider it maybe 1.3× more difficult to use compared to its original position, which is great tradeoff to be able to get Shift on the home row.

### Functional Keys

![current layout](./Images/functionalkeys.png)

Accessible by either modifier.

- Backspace is on the left pinky, to be intuitive with the direction you are deleting.

- Delete is on D, and is intuitive with the direction you are deleting.

- Escape for some reason, feels best on the Ring Finger, rather than the pinky.

- End and Home are inspired by a colemak Vim configuration:

- Insert, which will go to the beginning of the line before editting.
  Append being on the T, which goes the opposite direction.
  Backspace is used 10× more ( Meaning that I will use the Home Row position 10× more, rather than its default position. ).

- Delete is used about 20× more.

- Escape is used about 15× more.

- Home and End is used about 200× more often and utilized far more often, being especially useful in editting documents outside a vim environment.

## Source

Refer to this [stackoverflow
post](https://stackoverflow.com/questions/14981498/modified-colemak-for-programming)
