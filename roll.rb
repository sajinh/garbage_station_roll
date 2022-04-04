require 'yaml'
require 'pp'

ONE_WEEK_IN_SECS = 7*24*60*60

def find_next_stat_file(status_file,mon,year)

  fmt_mon = "%02d" % (mon-1)
  if mon==1
    fmt_mon = "12"
  end
  status = YAML.load_file(status_file)
  # The last date when a volunteeer was assigned to manage the garbage station

  last_dy, last_mon, last_yr = status["last"]["date"].split("-")

  last_upd = Time.local(last_yr,last_mon,last_dy)
  # Next update should start from next month; abort otherwise

  next_upd = last_upd + ONE_WEEK_IN_SECS

  # Collect next dates for assignment
  # only one month at a time is considered
  

  next_dates = []
  while(next_upd.mon <= mon) do
    next_dates << next_upd
    next_upd += ONE_WEEK_IN_SECS
    break if (next_upd.mon==1 and mon==12)
    break if (next_upd.mon==2 and mon==13)

  end
  fmt_mon = "%02d" % (next_upd.mon-1)
  if next_upd.mon==1
    fmt_mon = "12"
  end
  next_stat_fil = "#{next_upd.year}#{fmt_mon}.yml"
  if next_upd.mon==1
    next_stat_fil = "#{(next_upd.year-1)}#{fmt_mon}.yml"
  end
  memb_siz = next_dates.length
  return [memb_siz, next_stat_fil, next_dates]
end


# shift volunteer out of the apa_num array if in current roll
# 
def shift_if_recent_volunteer(apa_num,volunteers,filnam)
  arr=[]
  return [] unless volunteers
  volunteers.each do |volunteer|
    volunteered_volunteer = apa_num.delete(volunteer.split(",")[0].strip.split("--")[1].strip)
    arr << volunteered_volunteer if volunteered_volunteer
  end
  arr.map! {|a| "#{a}, #{filnam}"}
end

def next_volunteers(memb_siz,stat_fils,folks,members)
  # stat_fils is collectively a database of previous volunteers
  # roll_list is a list of occupied apartments and includes name of volunteers
  # 
  # We remove aparments listed in each of the stat_fils starting from the most recent 
  # from the roll_list into a list of recent_volunteers
  # After we iterate through each of the stat_fils, the apartments remaining in
  # the roll_list did not previously volunteer for the garbage station management
  # 
  # We choose these as our new volunteers
  # 
  # If the number of volunteers are not enough, we add them as needed from the 
  # list of 'recent_volunteers' starting from the bottom.
  #
 
  apa_members = folks[members]
  apa = apa_members.map {|e| e.split(",")[0].strip}
  recent_volunteers=[]
  stat_fils.each do |stat_fil|
    status = YAML.load_file(stat_fil)

    shifted_volunteer = shift_if_recent_volunteer(apa,status[members],stat_fil)
    recent_volunteers << shifted_volunteer unless shifted_volunteer.empty?
  end
  recent_volunteers.flatten! # list of recent volunteers sorted chronologically descending
                             # apa contains apartments which did not volunteer

  
  apa << recent_volunteers.map {|rv| rv.split(",").first}.reverse
  apa.flatten!
  next_volunteers = []
  apa[0..memb_siz-1].each do |folk|
    idx = apa_members.index {|sa| sa.match(folk)}
    next_volunteers << apa_members[idx]
  end
  return next_volunteers
end

def abort_on_future_file(stat_fil,mon,year)
  yyyymm = stat_fil.split(".")[0].to_i
  #chck_str = Time.now.strftime("%Y%m").to_i
  if mon==1
    expected_file_prefix = Time.new(year-1,12).strftime("%Y%m").to_i
  else
    expected_file_prefix = Time.new(year,mon-1).strftime("%Y%m").to_i
  end
  abort("Please remove roll file into the future #{stat_fil} before continuing") if  yyyymm > expected_file_prefix
end
def abort_if_parent_absent(stat_fil,mon,year)
  yyyymm = stat_fil.split(".")[0].to_i
  if mon==1
    expected_file_prefix = Time.new(year-1,12).strftime("%Y%m").to_i
  else
    expected_file_prefix = Time.new(year,mon-1).strftime("%Y%m").to_i
  end
  abort("You don't have an ancestor roll file for required month #{mon}") if  yyyymm < expected_file_prefix
end

def schedule_folks(mon,year)
  folks = YAML.load_file("mm.yml")

  # we need to abort if we find anomalous files
  # present
  # anomalous == if a stat_fil for a future date is present
  #   in the file system
  stat_fils = Dir.glob("20*.yml").sort.reverse

  # find name of next status file and memb_siz (number of volunteers needed)
  stat_fil = stat_fils.first
  abort_on_future_file(stat_fil,mon,year)
  abort_if_parent_absent(stat_fil,mon,year)
  memb_siz, next_stat_fil, next_dates = find_next_stat_file(stat_fil,mon,year)

  abort("Status files collide") if stat_fil == next_stat_fil
  abort("Output file exists; will not overwrite") if File.exist? next_stat_fil


  rotAB = next_volunteers(memb_siz, stat_fils, folks, "membersAB")
  rotCD = next_volunteers(memb_siz, stat_fils, folks, "membersCD")

  # Write status file

  status = YAML.load_file(stat_fil) # load data from last database
  status["last"]["ab"]=rotAB.last.split(",").first
  status["last"]["cd"]=rotCD.last.split(",").first
  status["last"]["date"]=next_dates.last.strftime("%d-%m-%Y")

  fmt_next_dates = next_dates.map {|d| d.strftime("%d %b")}
  stat_members_AB = (fmt_next_dates.zip(rotAB)).map {|m| m.join(" -- ")}
  stat_members_CD = (fmt_next_dates.zip(rotCD)).map {|m| m.join(" -- ")}

  status["membersAB"] = stat_members_AB
  status["membersCD"] = stat_members_CD
  status["prepared_on"] = Time.now.strftime("%d-%m-%Y")
  File.write(next_stat_fil, status.to_yaml)
end

if ARGV.length < 1
  puts "Required argument -- the month of interest"
  puts "Optional argument -- the year"
  exit
end
arg_mon = ARGV[0]
arg_year = ARGV[1] || Time.now.year

schedule_folks(arg_mon.to_i, arg_year.to_i)
