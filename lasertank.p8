pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- lasertank
-- by tobiasvl
levels={
  {
    "0203030402040404000305001311100703030304040404140004000013120f03030303030303140b0004000003000003030303030307000418040d000900000309000006060600041804000404000003420400060504000419040e001300110300000006060516130e00040404000003040400000000000310030000030f0003420400040404040310030007040000030004400400000903100300001300110300040404000004031003000704000003000d00030000400305030000030f000305030309060606030303000004000003030d0b04040004031003000704001103030e0c040400000310030011110003000e000b04000a000f0f0300120f0f0f01",
    "boot camp",
    "this is the laser tank boot camp. it shows you a little of everything. the hardest thing is probably the mirror you need to move in the top right corner.",
    "jim kindley",
    2
  },
  {
    "04111111111111111111111111100000041211111111111111111111101000000412120000000000000000001010000004121200000000000000000010100000041212000000000000000000101005000412120000000000000500001010000004121200000000000000000010100000041212000000050000000000101000010412120000000000000000001010000004121200000000000000000010100000041212000000000000000000101000000412120000000000000000001010000004121200000000000000000010100000041212000000000000000000101000000212120f0f0f0f0f0f0f0f0f0f1000000412120f0f0f0f0f0f0f0f0f0f0f0500",
    "easy level conveyor",
    "shoot block on to the conveyor to\nstop the tank.",
    "reed",
    2
  },
}

difficulties={
  {"kids",10},
  {"easy",12},
  {"medium",11},
  {"hard",2},
  {"deadly",8}
}

modes={
  play=0,
  game_over=1,
  pause=2,
  hint=3
}

-- map direction and x,y coords to new coords
directions={
  [1]=function(x,y) return x-1,y end, --left
  [2]=function(x,y) return x+1,y end, --right
  [4]=function(x,y) return x,y-1 end, --up
  [8]=function(x,y) return x,y+1 end  --down
}

opposite_directions={
  [1]=2,
  [2]=1,
  [4]=8,
  [8]=4
}

-- map laser directions and mirrors to new laser direction
mirrors={
  [12]={[2]=4,[8]=1},
  [13]={[8]=2,[1]=4},
  [14]={[1]=8,[4]=2},
  [15]={[2]=8,[4]=1}
}

-- map laser direction and rotating mirror to new laser direction or rotated mirror
rotate_mirrors={
  [21]={[1]={obj=22},[2]={direction=4},[4]={obj=22},[8]={direction=1}},
  [22]={[1]={direction=4},[2]={obj=23},[4]={obj=23},[8]={direction=2}},
  [23]={[1]={direction=8},[2]={obj=24},[4]={direction=2},[8]={obj=24}},
  [24]={[1]={obj=21},[2]={direction=8},[4]={direction=1},[8]={obj=21}}
}

function _init()
  mode=modes.level_select
  selected_level=1
  page=0
end

function _update()
  if mode==modes.pause then
    mode=modes.play
  elseif mode==modes.hint then
    if (btnp()!=0) mode=modes.play
  elseif mode==modes.game_over then
    if (btnp(4)) load_level(selected_level) mode=modes.play
  elseif mode==modes.level_select then
    menuitem(1)
    menuitem(2)
    if btnp(2) then
      if (selected_level>1) selected_level-=1
      if (selected_level<(page*20)+1) page-=1
    elseif btnp(3) then
      if (selected_level<#levels) selected_level+=1
      if (selected_level>(page*20)+20) page+=1
    end
    if (btnp(4)) level=load_level(selected_level) mode=modes.play
  elseif mode==modes.play then
    menuitem(1,"show hint",function() mode=modes.hint end)
    menuitem(2,"level select",function() mode=modes.level_select end)
    if laser then
      move_laser()
    else
      if (not dynamic_actors[tank.y][tank.x]) detect_tank()
    end
    local under=static_actors[tank.y][tank.x].obj
    --if (under==3) win
    if (under==4) mode=modes.game_over
    if (under==1 or under==30 or under>64 or not last_direction) and not laser then
      -- as long as we're on solid ground and no laser is firing,
      -- we can control the tank
      control=true
    end
    if (under==16) move_tank(4)
    if (under==17) move_tank(2)
    if (under==18) move_tank(8)
    if (under==19) move_tank(1)
    if not control then
      if (under==25) move_tank()
      if (under==26) static_actors[tank.y][tank.x]={x=tank.x,y=tank.y,obj=4} move_tank()
      if (laser and laser.x==tank.x and laser.y==tank.y) mode=modes.game_over
    end
    local button=btnp()
    if button==0x40 then
      mode=modes.pause
    end
    if control and not laser and button==0x10 then
      laser={x=tank.x,y=tank.y,direction=tank.direction}
      move_laser()
    elseif button==0x20 then
      -- x
    elseif control and not laser and button!=0 then
      if tank.direction!=button then
        turn_tank(button)
      else
        move_tank(button)
      end
    end
  end
end

function _draw()
  if mode==modes.play then
    cls()
    for t in all({static_actors,dynamic_actors}) do
      for y=0,15 do
        for x=0,15 do
          local v=t[y][x]
          if (v) mset(v.x,v.y,v.obj)
        end
      end
      map()
    end
    if (laser) mset(laser.x,laser.y,laser.obj)
    mset(tank.x,tank.y,tank.obj)
    map()
  elseif mode==modes.game_over then
    local msg="you are dead !!!"
    rect(64-(#msg*2)-2,62,64+(#msg*2),70,8)
    rectfill(64-(#msg*2)-1,63,64+(#msg*2)-1,69,0)
    center(msg,64,8)
  elseif mode==modes.pause then
    rectfill(0,0,127,24,0)
    center(level.title)
    center("by",6,5)
    center(level.author,12)
    local difficulty=difficulties[level.difficulty]
    if difficulty then
      center(level.number.." - "..difficulty[1],18,difficulty[2])
    else
      center(tostr(level.number),18)
    end
  elseif mode==modes.hint then
    rectfill(0,25,127,127,0)
    local y=32
    center("hint:",y,5)
    for i=1,256,32 do
      y+=6
      print(sub(level.hint,i,i+32),0,y,7)
    end
  elseif mode==modes.level_select then
    cls()
    for i=(page*20)+1,(page*20)+20 do
      if i<=#levels then
        if selected_level==i then
          local y=peek(0x5f27)
          rectfill(peek(0x5f26),y,127,y+5,4)
        end
        local lvl=levels[i]
        if (difficulties[lvl[5]]) color(difficulties[lvl[5]][2]) else color(7)
        print(i.." "..lvl[2])
      end
    end
    if (page>0) print("\148",120,0)
    if ((page*20)+20<#levels) print("\131",120,114)
  end
end

function center(str,y,c)
  c=c or 7
  print(str,64-(#str*2),y,c)
end

function turn_tank(button)
  local tank_sprites={
    [1]=29,
    [2]=27,
    [4]=2,
    [8]=28
  }
  local spr=tank_sprites[button]
  if (spr) tank.direction,tank.obj=button,spr
  return
end

function move_tank(button)
  if (not button) button=last_direction
  if (not button) return
  last_direction=button
  local new_x,new_y=directions[button](tank.x,tank.y)
  if fget(mget(new_x,new_y),1) then
    -- solid object
    control=true
    last_direction=nil
  elseif new_x<0 or new_x>15 or new_y<0 or new_y>15 then
    -- out of bounds
    control=true
  else
    if mget(new_x,new_y)>64 then
      -- tunnel
      for t in all(tunnels[mget(new_x,new_y)]) do
        if not ((t.x==new_x and t.y==new_y) or dynamic_actors[t.y][t.x]) then
          tank.x,tank.y=t.x,t.y
          return
        end
      end
    end
    tank.x,tank.y=new_x,new_y
    local under=static_actors[new_y][new_x].obj
    if control then
      if (under==16) control=false
      if (under==17) control=false
      if (under==18) control=false
      if (under==19) control=false
      if (under==25) control=false
      if (under==26) control=false
    end
  end
end

function move_laser()
  local new_x,new_y=directions[laser.direction](laser.x,laser.y)
  if (new_x==tank.x and new_y==tank.y) mode=modes.game_over
  local obj=mget(new_x,new_y)
  if fget(obj,0) then
    -- movable object
    move_object(new_x,new_y,laser.direction)
  elseif rotate_mirrors[obj] then
    -- rotatable mirror
    laser.x,laser.y=new_x,new_y
    if rotate_mirrors[obj][laser.direction] and rotate_mirrors[obj][laser.direction].direction then
      laser.obj=(laser.direction==4 or laser.direction==8) and 32 or 33
      laser.direction=rotate_mirrors[obj][laser.direction].direction
    elseif rotate_mirrors[obj][laser.direction].obj then
      static_actors[new_y][new_x].obj=rotate_mirrors[obj][laser.direction].obj
      laser=nil
    end
  elseif fget(obj,1) and obj!=20 then
    -- solid object
    if (obj==7) static_actors[new_y][new_x].obj=1
    laser=nil
  elseif new_x<0 or new_x>15 or new_y<0 or new_y>15 then
    -- out of bounds
    laser=nil
  else
    laser.x,laser.y,laser.obj=new_x,new_y,(laser.direction==4 or laser.direction==8) and 32 or 33
  end
end

function move_object(x,y,direction)
  local new_x,new_y=directions[direction](x,y)
  local obj=mget(x,y)
  if (obj==8 and direction==8) or (obj==9 and direction==1) or (obj==10 and direction==4) or (obj==11 and direction==2) then
    -- destroy antitank
    dynamic_actors[y][x].obj+=28
    laser=nil
  elseif mirrors[obj] and mirrors[obj][direction] then
    laser.x,laser.y=x,y
    laser.obj=(laser.direction==4 or laser.direction==8) and 32 or 33
    laser.direction=mirrors[obj][direction]
  elseif new_x<0 or new_x>15 or new_y<0 or new_y>15 then
    -- move against out of bounds
    laser=nil
  elseif fget(mget(new_x,new_y),1) then
    -- move against solid object
    laser=nil
  elseif mget(new_x,new_y)==4 then
    -- move into water
    if (obj==6) static_actors[new_y][new_x]={x=new_x,y=new_y,obj=30}
    dynamic_actors[y][x]=nil
    laser=nil
    control=false -- todo: hack?
  else
    if mget(new_x,new_y)>64 then
      -- tunnel
      for t in all(tunnels[mget(new_x,new_y)]) do
        if not ((t.x==new_x and t.y==new_y) or (t.x==tank.x and t.y==tank.y) or (dynamic_actors[t.y][t.x] and not (t.x==x and t.y==y))) then
          dynamic_actors[t.y][t.x]={x=t.x,y=t.y,obj=dynamic_actors[y][x].obj}
          if (not (t.x==x and t.y==y)) dynamic_actors[y][x]=nil
          laser=nil
          control=false
          return
        end
      end
    end
    -- move object
    dynamic_actors[new_y][new_x]={x=new_x,y=new_y,obj=dynamic_actors[y][x].obj}
    dynamic_actors[y][x]=nil
    laser=nil
    control=false -- todo: hack?
  end
end

function detect_tank()
  for dir in all({2,1,8,4}) do
    local move,x,y=directions[dir],tank.x,tank.y
    repeat
      x,y=move(x,y)
    until fget(mget(x,y),1) or x<0 or x>15 or y<0 or y>15
    if (mget(x,y)==8 and dir==8) or (mget(x,y)==9 and dir==1) or (mget(x,y)==10 and dir==4) or (mget(x,y)==11 and dir==2) then
      laser={x=x,y=y,direction=opposite_directions[dir]}
      laser.obj=laser.direction==1 or laser.direction==2 and 35 or 34
      move_laser()
      break
    end
  end
end

function load_level(lvl_number)
  local lvl=levels[lvl_number]
  static_actors={}
  for y=0,15 do
    static_actors[y]={}
    for x=0,15 do
      static_actors[y][x]={x=x,y=y,obj=1} --ground
    end
  end
  dynamic_actors={}
  for y=0,15 do
    dynamic_actors[y]={}
    for x=0,15 do
      dynamic_actors[y][x]=nil
    end
  end
  tunnels={}
  for t=65,79,2 do
    tunnels[t]={}
  end
  for s=1,512,2 do
    y=((s-1)%32)/2
    x=flr((s-1)/32)
    local obj=tonum("0x"..sub(lvl[1],s,s+1))+1
    if obj==2 then
      tank={x=x,y=y,direction=4,obj=2}
    elseif fget(obj,0) then
      dynamic_actors[y][x]={x=x,y=y,obj=obj}
      static_actors[y][x]={x=x,y=y,obj=1}
    else
      static_actors[y][x]={x=x,y=y,obj=obj}
    end
  end
  for y=0,15 do
    for x=0,15 do
      obj=static_actors[y][x].obj
      if obj>64 then
        add(tunnels[obj],{x=x,y=y})
      end
    end
  end
  laser=nil
  control=true
  return {number=lvl_number,title=lvl[2],hint=lvl[3],author=lvl[4],difficulty=lvl[5]}
end
__gfx__
0000000044444444000bb000a4444444111cc11177777777eeeeeeee88588858000880000666666006666660066666600000000aa0000000eeeeee9aa988888e
000000004344434466c66c6657777774ccc1111176666665e22222288858885866566566666666606666666606666666000000a99a000000e22229a00a98ee8e
00700700444444446cc66cc65776c6741111111c76566565e2ee8ee8555555556656656666555550665555660555556600000a98e9a00000e2e89a0000a9ee8e
00077000444434436cc66cc65776c67411111cc176666665e2ee8ee858885888665665666656666866566566866665660000a988e29a0000e2e9a000000a988e
00077000444444446cc66cc65777777411ccc11176666665e28888885888588866566566665666686656656686666566000a9ee8e289a000e29a00000000a98e
00700700434444446cccccc654344444cc11111176566565e2ee8ee8588858886655556666555550665665660555556600a98ee8e2ee9a00e9a0000000000a9e
000000004444434466cccc6654444344111111cc76666665e2ee8ee855555555666666666666666066566566066666660a988888e2ee89a09a000000000000a9
000000004443444400000000544444441111cc1175555555e88888888858885806666660066666600008800006666660a9eeeeeee888889aa00000000000000a
566bb665555555555b6666b555555555777777774444444aa44444444444449aa9444444cccccccccccccccc0666666000000000066666601111111100000000
56bbbb65bb66bb665bb66bb566bb66bb7bbbbbb7434444a99a444444438849a44a948844ccccccccc0cc0cc006cccc6066cccc6606cccc601555555d00000000
5bb66bb56bb66bb656bbbb656bb66bb67b7cc7b744444a9449a4444448889a4444a98884ccc7cccccc0cc00c0cccccc06cccccc60cccccc01511d11d00000000
5b6666b566bb66bb566bb665bb66bb667bccccb74444a934449a44344889a434444a9884ccccccccccccccc00cc6666b6cc66cc6b6666cc01511d11d00000000
566bb66566bb66bb5b6666b5bb66bb667bccccb7344a98843889a444349a44443444a944cccccc7c0cc00ccc0cc6666b6cc66cc6b6666cc015dddddd00000000
56bbbb656bb66bb65bb66bb56bb66bb67b7cc7b744a9888448889a4449a4444444444a94ccccccccc00cc0cc0cccccc06cc66cc60cccccc01511d11d00000000
5bb66bb5bb66bb6656bbbb6566bb66bb7bbbbbb74a948844448849a49a444344444443a9c7ccccccccc0cc0c06cccc6066c66c6606cccc601511d11d00000000
5b6666b555555555566bb6655555555577777777a94444444444449aa44444444444444accccccccccc0cccc06666660000bb000066666601ddddddd00000000
000bb000000000000008800000000000000880000666066006660660066606600000000000000000000000000000000000000000000000000000000000000000
000bb000000000000008800000000000605665066060660060606606006066060000000000000000000000000000000000000000000000000000000000000000
000bb000000000000008800000000000660660666605505066055066050550660000000000000000000000000000000000000000000000000000000000000000
000bb000bbbbbbbb0008800088888888065005060650066806500506866005060000000000000000000000000000000000000000000000000000000000000000
000bb000bbbbbbbb0008800088888888605005606050066860500560866005600000000000000000000000000000000000000000000000000000000000000000
000bb000000000000008800000000000660550666605505066066066050550660000000000000000000000000000000000000000000000000000000000000000
000bb000000000000008800000000000606606066066060060566506006606060000000000000000000000000000000000000000000000000000000000000000
000bb000000000000008800000000000066066600660666000088000066066600000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000448888440000000044bbbb4400000000441111440000000044cccc440000000044aaaa440000000044eeee4400000000447777440000000044555544
0000000048800884000000004bb00bb40000000041100114000000004cc00cc4000000004aa00aa4000000004ee00ee400000000477007740000000045500554
000000008805508800000000bb0550bb000000001105501100000000cc0550cc00000000aa0550aa00000000ee0550ee00000000770550770000000055055055
000000008050050800000000b050050b000000001050050100000000c050050c00000000a050050a00000000e050050e00000000705005070000000050500505
000000008050050800000000b050050b000000001050050100000000c050050c00000000a050050a00000000e050050e00000000705005070000000050500505
000000008805508800000000bb0550bb000000001105501100000000cc0550cc00000000aa0550aa00000000ee0550ee00000000770550770000000055055055
0000000048800884000000004bb00bb40000000041100114000000004cc00cc4000000004aa00aa4000000004ee00ee400000000477007740000000045500554
00000000448888440000000044bbbb4400000000441111440000000044cccc440000000044aaaa440000000044eeee4400000000447777440000000044555544
__gff__
0000000000020302030303030303030300000000020202020200000000000000000000000202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
