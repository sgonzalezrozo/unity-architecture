# Builds the list mockups used in docs/USAGE.md. Run from this folder: python3 mockups.py,
# then render each SVG to PNG (macOS: qlmanage -t -s 1400 -o . store-list.svg, and rename store-list.svg.png).
from xml.sax.saxutils import escape
F='font-family="Helvetica Neue, Helvetica, Arial, sans-serif"'
def text(x,y,s,size=24,fill="#fff",weight="normal",anchor="start"):
    return f'<text x="{x}" y="{y}" {F} font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{escape(s)}</text>'
def rect(x,y,w,h,fill,r=16,extra=""):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" {extra}/>'
def coin(cx,cy,r): return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#f5c542" stroke="#b8860b" stroke-width="3"/>'
def gem(cx,cy,s,fill="#4fc3f7"):
    return f'<polygon points="{cx},{cy-s} {cx+s*0.8},{cy-s*0.2} {cx},{cy+s} {cx-s*0.8},{cy-s*0.2}" fill="{fill}" stroke="#0277bd" stroke-width="3"/>'
def topbar(title):
    return [rect(0,0,720,140,"#1b1d3a",0), text(40,92,title,44,weight="bold"), rect(430,52,250,56,"#2c2f5a",28), coin(462,80,18), text(495,91,"12,450",28,weight="bold")]

def store():
    o=[rect(0,0,720,1280,"#12132a",0)]+topbar("Store"); y=170
    def header(y,title,note=None):
        r=[text(40,y+38,title,30,"#ffd54f","bold")]
        if note: r.append(text(680,y+38,note,22,"#9fa3d1",anchor="end"))
        return r+[f'<line x1="40" y1="{y+56}" x2="680" y2="{y+56}" stroke="#2f325e" stroke-width="2"/>']
    def item(y,icon,name,amount,price,tag=None,owned=False):
        r=[rect(40,y,640,130,"#23264a"), rect(60,y+15,100,100,"#2f3363",14), icon(110,y+65), text(185,y+55,name,28,weight="bold"), text(185,y+95,amount,24,"#b9bce6")]
        if tag: r+=[rect(185,y-14,110,30,"#e53935",15), text(240,y+8,tag,18,weight="bold",anchor="middle")]
        if owned: r+=[rect(500,y+35,160,60,"#3a3d66",30), text(580,y+74,"Owned",24,"#9fa3d1","bold","middle")]
        else: r+=[rect(500,y+35,160,60,"#43a047",30), text(580,y+74,price,26,weight="bold",anchor="middle")]
        return r
    o+=header(y,"Daily Deals","Resets in 05:42:10"); y+=80
    o+=item(y,lambda x,yy: coin(x,yy,34),"Coin Pouch","5,000 coins","$0.99","-50%"); y+=150
    o+=item(y,lambda x,yy: gem(x,yy,36,"#ba68c8"),"Starter Pack","Gems + Booster","",owned=True); y+=170
    o+=header(y,"Coins"); y+=80
    o+=item(y,lambda x,yy: coin(x,yy,30),"Handful","1,000 coins","100 gems"); y+=150
    o+=item(y,lambda x,yy: coin(x,yy,36),"Chest","12,000 coins","900 gems"); y+=170
    o+=header(y,"Gems"); y+=80
    o+=item(y,lambda x,yy: gem(x,yy,30),"Gem Bag","80 gems","$1.99")
    return o

def events():
    o=[rect(0,0,720,1280,"#12132a",0)]+topbar("Events")
    def head(y,color,title,timer,open_):
        pts = f"626,{y+66} 640,{y+52} 654,{y+66}" if open_ else f"626,{y+52} 640,{y+66} 654,{y+52}"
        return [rect(60,y+15,90,90,color,16), text(105,y+75,"★",44,anchor="middle"), text(175,y+55,title,30,weight="bold"), text(175,y+92,timer,22,"#ffb74d"),
                f'<polyline points="{pts}" fill="none" stroke="#c5c8f0" stroke-width="5" stroke-linecap="round"/>']
    def closed(y,color,title,timer): return [rect(40,y,640,120,"#23264a")]+head(y,color,title,timer,False)
    y=170; o+=closed(y,"#7e57c2","Dragon Hunt","Ends in 2d 04h"); y+=140
    H=540
    o+=[rect(40,y,640,H,"#2a2d58",16,'stroke="#ffd54f" stroke-width="3"')]+head(y,"#ef6c00","Harvest Festival","Ends in 18h 30m",True)
    d=y+130
    o+=[f'<line x1="60" y1="{d}" x2="660" y2="{d}" stroke="#3a3d6e" stroke-width="2"/>',
        text(60,d+45,"Collect pumpkins in any level to fill the",24,"#c5c8f0"), text(60,d+78,"festival bar and unlock the next reward.",24,"#c5c8f0"),
        text(60,d+135,"Progress",24,"#9fa3d1"), text(660,d+135,"7 / 10",26,weight="bold",anchor="end"),
        rect(60,d+150,600,32,"#15173a",16), rect(60,d+150,420,32,"#66bb6a",16),
        text(60,d+230,"Rewards claimed",24,"#9fa3d1"), text(660,d+230,"2 / 5",26,weight="bold",anchor="end")]
    for i in range(5): o.append(f'<circle cx="{100+i*120}" cy="{d+270}" r="20" fill="{"#ffd54f" if i<2 else "#3a3d6e"}"/>')
    o+=[rect(220,d+316,280,64,"#43a047",32), text(360,d+358,"Continue",28,weight="bold",anchor="middle")]
    y+=H+20; o+=closed(y,"#00897b","Speed Run","Starts now · 3d left"); y+=140
    o+=closed(y,"#5c6bc0","Puzzle Week","Starts in 1d 06h")
    return o

def compose(name, phone, title, notes):
    W=1400
    o=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{W}" viewBox="0 0 {W} {W}">', f'<rect width="{W}" height="{W}" fill="#0b0c1c"/>',
       '<clipPath id="c"><rect width="720" height="1280" rx="36"/></clipPath>',
       '<g transform="translate(40,60)"><g clip-path="url(#c)">', *phone, '</g></g>',
       '<rect x="40" y="60" width="720" height="1280" rx="36" fill="none" stroke="#3a3d6e" stroke-width="4"/>', text(810,120,title,36,"#ffd54f","bold")]
    y=180
    for h, lines in notes:
        o.append(text(810,y,h,26,"#ffffff","bold")); y+=38
        for l in lines: o.append(text(830,y,l,21,"#b9bce6")); y+=31
        y+=24
    o.append('</svg>')
    open(name+'.svg','w').write('\n'.join(o))

compose('store-list',store(),'Store: sectioned list',[
 ("One SectionedScroller",["StoreScroller : SectionedScroller<","  StoreItemData, StoreSectionData>","StoreModel builds the SectionedSource"]),
 ("Header slot: ISlot<StoreSectionData>",["Title, optional reset timer","The timer text comes from the Model"]),
 ("Item slot: ISlot<StoreItemData>",["Icon, name, amount, optional tag","Price or Owned: two state roots","UI Content + Action (PREFAB-17)"]),
 ("Buy",["BuyItemController → StoreModel.Buy","Owned: no Action in that state (INPUT-04)"]),
 ("Sections",["Daily Deals, Coins, Gems","Order and contents come from the Model"]),
])
compose('event-list',events(),'Events: expandable list',[
 ("One Scroller, expandable slots",["EventScroller : Scroller<EventData>","Slot Model: IExpandableSlot<EventData>","One open at a time: list default"]),
 ("Closed card",["Icon, title, time left, chevron","Tap the header: ToggleExpanded()","The list measures and moves the slots"]),
 ("Open card: details",["Description text","Progress: Image (Filled), 7 / 10","Rewards claimed: count + dots, 2 / 5","No Slider (ARCH-05)"]),
 ("Action button",["Continue when joined, Enter when not:","two state roots in the details","EnterEventController → EventsModel"]),
 ("State",["Expanded, joined and progress live in","the item or the Model (LIST-07)"]),
])
