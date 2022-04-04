require 'erb'
require 'yaml'
require 'pp'
require 'base64'
require 'mail'



class PrepareMail
  def initialize(mon,year)
    @mon = mon
    @year = year
  end

  def str_month(mon)
    Date::MONTHNAMES[@mon]
  end

  def month_of_duty
    "#{str_month(@mon)} #{@year}"
  end

  def mail_subject
    "Duties at the garbage collection station (#{month_of_duty})"
  end

  def mail_text
    template = ERB.new(File.read('body.txt.erb'))
    template.result(binding)
  end

  def prepare_mail
    fname = "#{@year}#{('%02d' % @mon)}.yml"
    puts "Preparing mail for #{month_of_duty}"
    puts "Opening #{fname}"
    folks = YAML.load_file(fname)
    @folksAB = folks["membersAB"].join("\n")
    @folksCD = folks["membersCD"].join("\n")
    mail_text
  end

  def send_mail(mail_text)
  end
end

if ARGV.length < 1
  puts "We need one argument -- the month of interest"
  puts "Optional argument -- the year"
  exit
end

arg_mon = ARGV[0]
arg_year = ARGV[1] || Time.now.year


mail = PrepareMail.new(arg_mon.to_i,arg_year.to_i)
mail_text = mail.prepare_mail
mail_subject = mail.mail_subject

def get_passwd
  Dir.chdir("#{ENV['HOME']}/.d9aF1UBoL5FsandeYuMeanZ") do
    File.basename(Dir.glob("*.yml").first,".yml").reverse.chop.chop.chop.chop.chop.reverse
  end
end

options = { :address              => "<full address of your mail server>",
            :port                 => 465,
            :domain               => '<your domain>
            :user_name            => '<your_user_name>',
            :password             => Base64.decode64(get_passwd+"=\n"),
            :authentication       => :login,
            :ssl                  => true,
            :openssl_verify_mode  => 'none'
          }

Mail.defaults do
  delivery_method :smtp, options
end

mail = Mail.new do
  from     '<your_user_name>@<your_domain>'
  to       ['<mailing group 1'>,
           '<mailing group 2'>,
           '<mailing group 3'>,
           '<mailing group 4'>]
  subject  mail_subject
  body     mail_text
  add_file :filename => 'how_to_dispose_garbage.pdf', :content => File.read('./how_to_dispose_garbage.pdf')
  add_file :filename => 'garbage_collection_chart.pdf', :content => File.read('./garbage_collection_chart.pdf')
end
mail.deliver!
