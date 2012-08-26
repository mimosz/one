# -*- encoding: utf-8 -*-
require 'digest/md5'
require 'nestful'

class Smsbao

  def initialize(login, passwd)
    @login = login
    @passwd = Digest::MD5.hexdigest(passwd)
  end

  # 发送短信
  def send(mobile, content, limit = { content: 64, mobile: 300 }) 
    if mobile.is_a?(Array)
      if content.size > (limit[:content] || default_limit[:content])
        { success: false, message: '批量发送，禁止长短信，收费加倍！' }
      else
        counter = 0
        total = mobile.count
        mobile.each_slice( (limit[:mobile] || default_limit[:mobile]) ).to_a.each do |mobiles| # 最大支持300为一组进行发送。
          response = client('send', { m: mobiles.join(','), c: content })
          stat = status(response)
          if stat[:success]
            counter += mobiles.count
            puts "剩余，#{(total-counter)}/#{total}条，"
          else
            return stat.merge({count: counter})
          end
        end
        return { success: true, message: '短信队列成功', count: counter}
      end
    else
      response = client('send', { m: mobile, c: content })
      stat = status(response)
      stat.merge({count: 2}) if content.size > (limit[:content] || default_limit[:content])
    end
  end

  # 查询余额
  def balance
    response = client('balance')
    return status(response)
  end

  private

  def default_limit # 默认限制
    { content: 64, mobile: 300 }
  end

  def status(resp)
    arr = resp.split("\n")
    code = arr[0]
    message = case code
      when '0'
        if arr[1].nil?
          '短信发送成功'
        else
          vals = arr[1].split(",")
          {sent: vals[0].to_i, balance: vals[1].to_i}
        end
      when '30'
        '密码错误'
      when '40'
        '账号不存在'
      when '41'
        '余额不足'
      when '42'
        '帐号过期'
      when '43'
        'IP地址限制'
      when '50'
        '内容含有敏感词'
      when '51'
        '手机号码不正确'
    end
    { success: (code == '0'), message: message }
  end

  def gw_url
    'http://api.smsbao.com'
  end

  def method_path
    { send: '/sms', balance: '/query' }
  end

  def client(method, params={})
    Nestful.get gw_url + method_path[method.to_sym], params: { u: @login, p: @passwd }.merge(params)
  end
end