# -*- encoding: utf-8 -*-
require 'csv'
require 'smsbao'

class SendCsv < Smsbao
  def initialize(login, passwd)
    @smser = Smsbao.new(login, passwd)
  end

  def import(csv_file, col_sep=',') # MAC下为;
    lines  = ::CSV.read(csv_file, 'rb:GB18030:UTF-8', headers: true, col_sep: col_sep)
    if lines.headers.include?(labels[:m] && labels[:c])
      result = []
      mobile = []
      set_fields(lines.headers) # 自定义

      lines.each do |line|
        if line[ labels[:m] ]
          if fields.empty? # 无自定义，可群发
            if content && line[ labels[:c] ]
              result << send(mobile, content) # 内容变动，发前一批次
              mobile.clear # 清空手机号
            end

            if line[ labels[:c] ]
              @content = line[ labels[:c] ] # 新内容
            end
            # 收集手机号
            mobile << line[ labels[:m] ]
          else
            result << send_tmpl(line) # 构造自定义内容，只能单发
          end
        end
      end
      result << send(mobile, content)
      return result.compact
    else
      puts "格式错误：必须包含：#{labels.values.join('、')}。"
    end
  end

  private

  def labels
    { m: '手机号', c: '短信内容' }
  end

  def send(mobile, content)
    unless mobile.empty?
      mobile = mobile[0] unless mobile.count > 1
      return @smser.send(mobile, content, true) 
    end
  end

  def content
    return @content.strip if defined?(@content)
  end

  def content=(str)
    @content = str
  end

  def fields
    return @fields if defined?(@fields)
  end

  def set_fields(headers)
    result   = {}
    headers -= labels.values
    unless headers.empty?
      headers.each do |header|
        unless header.nil?
          arr = header.split('|')
          if result.has_key?(header.to_s)
            puts "格式错误：重复自定义 #{header.to_s}。"
          else
            result[header.to_s] = { word: "{#{arr[0]}}", default: (arr[1] || '') }
          end
        end
      end
    end
    @fields = result
  end

  def send_tmpl(sms) # 构造自定义内容，只能单发
    @content    = sms[ labels[:c] ] if sms[ labels[:c] ]
    content_dyn = content.clone
    fields.each do |key, field|
      content_dyn.gsub!(field[:word], (sms[key] || field[:default]) ) # 剔汉字
    end
    return send([ sms[ labels[:m] ] ], content_dyn)
  end

end