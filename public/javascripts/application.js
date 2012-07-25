!function ($) {
	$(function(){
		var start_at = $('input[name="start_at"]');
		var end_at = $('input[name="end_at"]');
		$('.calendar').DatePicker({
			date: [ start_at.val(), end_at.val() ],
			current: end_at.val(),
			calendars: 2,
			starts: 1,
			onChange: function(formated, dates){
				start_at.val(formated[0]);
				end_at.val(formated[1]);
			}
		});
		$('#trades.nav-tabs a').click(function (e) {
		  e.preventDefault();
		  $(this).tab('show');
		})
		$('.chzn-select').chosen();
		$(".chzn-select-deselect").chosen({allow_single_deselect:true});
		$('.dropdown-toggle').dropdown();
			$('#rates tr#service_rate td').graphup({colorMap: 'greenPower'});
			$('#rates tr#speed_rate td').graphup({colorMap: 'greenPower'});
			$('#rates tr#refund_rate td').graphup({colorMap: 'burn'});
			$('#subusers td.payment').graphup({
				min: 0,
				cleaner: 'strip',
				painter: 'bars',
				colorMap: [[145,89,117], [102,0,51]]
			});
		 $('[rel=popover]').popover({placement: 'bottom'});
		 $('[rel=tooltip]').tooltip({});
		 $('label.btn.active').each(function() {
		        var label = $(this), inputId = label.attr('for');
				$('#' + inputId).prop('checked', true);
		 });
	// fix sub nav on scroll
	    var $win = $(window)
	      , $nav = $('.subnav')
	      , navTop = $('.subnav').length && $('.subnav').offset().top - 40
	      , isFixed = 0

	    processScroll()

	    $win.on('scroll', processScroll)

	    function processScroll() {
	      var i, scrollTop = $win.scrollTop()
	      if (scrollTop >= navTop && !isFixed) {
	        isFixed = 1
	        $nav.addClass('subnav-fixed')
	      } else if (scrollTop <= navTop && isFixed) {
	        isFixed = 0
	        $nav.removeClass('subnav-fixed')
	      }
	    }
	})
}(window.jQuery)