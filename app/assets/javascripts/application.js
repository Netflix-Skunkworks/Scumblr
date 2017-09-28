// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery_sparklines

//= require foundation
// require foundation_datatables
//= require foundation_datepicker
//= require jquery.datetimepicker

//= require Chart.bundle
//= require chartkick
//= require results
//= require searches
//= require select2
//= require d3
//= require sonic
//= require nvd3.min
// require active_scaffold
// require turbolinks

//= require_self
//= require zeroclipboard




Chart.defaults.global.title.fontSize=24

// Better tool tips
betterTooltips = function()
{
  //selectors = $("*[data-tooltip]").map(function(i,el) {return el.data("selector")})
  $(".bettertooltip").removeAttr("data-tooltip")

  $(".has-tip.bettertooltip").click(function(e) {
    selector = $(this).data("selector")
    tip = $("span[data-selector="+selector+"]")
    tip.css({ "left" : $(this).offset()["left"],
              "top"  : $(this).offset()["top"]+5+$(this).outerHeight()})
    tip.show()


  })

  $("span[data-selector].tooltip").on("mouseenter", function(e)
  {
    console.log("entering tip")
    timeoutId = $(this).data("timeout")
    clearTimeout(timeoutId)
    $(this).removeAttr("data-timeout")

  }).on("mouseleave", function(e) {
    console.log("leaving tip")
    el = $(this)
    timeoutId = setTimeout(function(){
      el.hide()
    },500)
    $(this).data("timeout", timeoutId)

  })


  $(".has-tip.bettertooltip").on("mouseenter", function(e)
  {
    selector = $(this).data("selector")
    tip = $("span[data-selector="+selector+"]")
    timeoutId = tip.data("timeout")
    clearTimeout(timeoutId)
    tip.removeAttr("data-timeout")

  }).on("mouseleave", function(e) {
    selector = $(this).data("selector")
    tip = $("span[data-selector="+selector+"]")
    timeoutId = setTimeout(function(){
      tip.hide()
    },500)
    tip.data("timeout", timeoutId)

  })
}



this.SearchStatusPoller = {
  poll: function(force_poll) {
    if(typeof force_poll !== 'undefined' && force_poll)
    {
      return setTimeout(this.request, 0);
    }
    else
    {
      return setTimeout(this.request, 10000);
    }

  },
  request: function() {
    return $.get($('#status_notifications').data('url'), {
      after: $('.status').last().data('id')
    });
  },
  addStatuses: function(statuses) {
    if (statuses.length > 0) {
      $('#status_notifications').html($(statuses));
    }
    return this.poll();
  }
};


var create_preloader = function()
{
  $("#preloader-modal").remove();
  $("body").append('<div id="preloader-modal" style="height:500px" class="reveal-modal" data-reveal><h2 class="centered">Loading...</h1><div class="preloader" ></div></div>')
  $("#preloader-modal").foundation('reveal','open')
  show_preloader();
}


var hide_preloader = function()
{


  //Insert small delay to ensure modal has had enough time to open--otherwise the modal will not close
  setTimeout(
    function()
    {
      preloader.stop()
      $(".preloader").html("")
      $(".preloader").hide();
      $("#preloader-modal").foundation('reveal','close')
    }, 500)
}


var preloader = null

function camelToSnake(str) {
  return str.replace(/\W+/g, '_')
            .replace(/([a-z\d])([A-Z])/g, '$1_$2')
            .toLowerCase();
}


var show_preloader = function()
{

  //Preloader

  var preloader_config = {

    width: 100,
    height: 100,

    stepsPerFrame: 1,
    trailLength: 1,
    pointDistance: .025,

    strokeColor: '#05E2FF',

    fps: 20,

    setup: function() {
      this._.lineWidth = 2;
    },
    step: function(point, index) {

      var cx = this.padding + 50,
        cy = this.padding + 50,
        _ = this._,
        angle = (Math.PI/180) * (point.progress * 360);

      this._.globalAlpha = Math.max(.5, this.alpha);

      _.beginPath();
      _.moveTo(point.x, point.y);
      _.lineTo(
        (Math.cos(angle) * 35) + cx,
        (Math.sin(angle) * 35) + cy
      );
      _.closePath();
      _.stroke();

      _.beginPath();
      _.moveTo(
        (Math.cos(-angle) * 32) + cx,
        (Math.sin(-angle) * 32) + cy
      );
      _.lineTo(
        (Math.cos(-angle) * 27) + cx,
        (Math.sin(-angle) * 27) + cy
      );
      _.closePath();
      _.stroke();

    },
    path: [
      ['arc', 50, 50, 40, 0, 360]
    ]
  }

  preloader = new Sonic(preloader_config)

  $(".preloader").append(preloader.canvas)

  preloader.canvas.style.marginTop = "100px"
  preloader.canvas.style.marginLeft = "50%"
  preloader.canvas.style.position = "relative"
  preloader.canvas.style.left = "-50px"

  preloader.play();
  $(".preloader").show();


}

//Start polling for events
$(function(){

  SearchStatusPoller.poll(true);
})

// Prevents refresh buttons in accordion headers from
// closing the accordion. Registered outside of ready
// to prevent binding/executing multiple times 
$(function(){
  $(document).on('click', "a > form > input.refresh", function(event) {
    event.stopPropagation();
  });

});

//Autosubmit facets form when a select box is changed. If inside ready submits multiplet times.
$(document).on("change select2:change select2:select select2:unselect", "form.facets select",function(){
    $(this).closest("form").submit();
  })

$(document).on("change", ".hide-toggle",function(){
    
    if((!$(this).hasClass("reverse-toggle") && this.checked) || (!this.checked && $(this).hasClass("reverse-toggle")))
    {
      $($(this).data("toggle")).show();
    }
    else
    {
      $($(this).data("toggle")).hide();
    }
  })

$(document).on('click', '.submit_form_link', function(e) {
 e.preventDefault();
 $(this).closest('form').submit();
});

$(document).on('click', '.close-modal', function() {
    $(".reveal-modal").foundation('reveal','close')
})

$(document).on('click', '.close-modal-on-submit', function() {
    form = $(this).parent("form")[0]
    if(form.checkValidity() == false)
    {
      msg="Error submitting form:"
      $(form).find( ":invalid" ).each( function( index, node ) {

          // Find the field's corresponding label
          
          label = $( "label[for=" + node.id + "] ").text().replace(/\  +/g,"").replace(/\*/g,"").replace(/\n/g,"").replace(/\t/g,"")
          message = node.validationMessage || 'Invalid value.';

          msg += "\r\n - " + label + ": " + message
      });
      alert(msg);
      return false;
    }
    else
    {
      $(".reveal-modal").foundation('reveal','close') 
    }

      
})

$(document).on('click', '.remote-form', function() {
  $("#preloader-modal").remove();
  $("body").append('<div id="preloader-modal" style="height:500px" class="reveal-modal" data-reveal>'+ $(this).data("form") +' </div></div>')
  $("#preloader-modal").foundation('reveal','open')
  $.ajax({
    method: "GET",
    url: $(this).data("form-path"),
    data: {}
  })
    .done(function( msg ) {

    });
  // show_preloader();
  return false;
})

var ready = function(){

  
  

  $('.datepicker').fdatepicker()
  $('.datetimepicker').datetimepicker({
    format: 'm/d/Y H:i'
  });




  //header_color();





  //Setup foundation
  $(document).foundation();

  //Setup sparklines

 $('.sparkline').sparkline('html', {
    type: 'line',
    width: '100px',
    lineColor: '#074e68',
    fillColor: undefined,
    spotRadius: 0,


  });


 $('.filterable-reset').click(function(e) {
  $("dl.filterable dd").addClass("active")
  $('*[data-filterable-'+group+"]").show();
 });


 $('dl.filterable dd').click(function(e)
 {
    $(this).siblings().removeClass("active")
    $(this).addClass("active")


    $('*[data-filterable-group]').each(function(i,obj) {
      group = $(obj).data("filterable-group")
      $('*[data-filterable-'+group+"]").show();
    });

    $('*[data-filterable-group]').each(function(i,obj) {
      group = $(obj).data("filterable-group")
      $(obj).find("dd:not(.active) a[data-filterable-value]").each(function(i,obj2) {
        value=$(obj2).data("filterable-value")
        console.log("Hiding: " + '*[data-filterable-'+group+"='"+value+"']")
        $('*[data-filterable-'+group+"='"+value+"']").hide();

      })
    })


    return false;


 });

 $(".updateable-update").click(function(e){



    url = $(e.target).data("updateable-url")
    ids = $.map($(".updateable:visible"), function(i,k) {return $(i).data("updateable-id")})
    data = $(e.target).data("updateable-parameters").replace("##ids##",String(ids))


    parent = $(e.target).parent().parent()




    $.ajax({
      method: "POST",
      url: url,
      data: data
    })
      .done(function( msg ) {

      });

    return false;
 })


  //Load default select2 boxes
  $(".select2").select2();

  

  $(".select2").removeClass("select2");
  $(".select2-tags").each(function() {
    tags = $(this).data('tags') || []
    $(this).select2({tags: tags,tokenSeparators: [',']})
  });
  $(".select2-tags").removeClass("select2-tags");


  //Load custom select2 boxes
  $(".remote_select2").each(function() {
    //alert( this.attr("data-path"));
    var context_object = this
    $(this).select2({
        placeholder: "Please choose",
        allowClear: true,
        minimumInputLength: 0,
        multiple: $(context_object).attr("data-multiple") == true || $(context_object).attr("data-multiple") == "true",

        ajax: {
            url: function() {return this.attr("data-path") },
            dataType: 'json',
            quietMillis: 300,

            data: function (search, page) {
                return {
                    q: search,
                    per_page: 25,
                    page: page,
                };
            },

            results: function (data, page) {

              var more = (page * 25) < data.meta.total; // whether or not there are more results available
              // notice we return the value of more so Select2 knows if more results can be loaded

              return {results: data[$(context_object).attr("data-object")], more: more};
            }


        },
        createSearchChoice:function(term, data) {
            if($(context_object).attr("data-create-new"))
            {
              if ($(data).filter(function() {
              return term.localeCompare(this.text)===0;
              }).length===0)
              {

                d = {}
                  d[$(context_object).attr("data-attribute")] = term
                if($(context_object).attr("data-id-attribute") != undefined)
                  d[$(context_object).attr("data-id-attribute")] = term
                else
                  d.id = term

                return d
              }
            }
            return []
          },
        tokenSeparators: [","],
        escapeMarkup: function (markup) {
            var replace_map = {
                '\\': '&#92;',
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&apos;',
                "/": '&#47;'
            };

            return String(markup).replace(/[&<>"'/\\]/g, function (match) {
                    return replace_map[match[0]];
            });

            return markup;
          },
        formatResult: function (item) { return this.escapeMarkup(item[$(context_object).attr("data-attribute")]); },


        formatSelection: function (item) {  return this.escapeMarkup(item[$(context_object).attr("data-attribute")]); },
        initSelection: function (element, callback) {


            var data = [];
            if($(context_object).attr("data-initial") != undefined && $(context_object).attr("data-initial") != "placeholder_value")
            {
              data = $(context_object).data("initial")
              // $(context_object).attr("value", JSON.stringify(data))
              callback(data);
              

            }
            else if($(context_object).attr("data-parse-initial") != undefined)
            {
              $(element.val().split(",")).each(function () {

                d = {}
                d[$(context_object).attr("data-attribute")] = this
                if($(context_object).attr("data-id-attribute") != undefined)
                  d[$(context_object).attr("data-id-attribute")] = this
                else
                  d.id = this



                data.push(d);
              });
            
            callback(data);

          }

        },
        id: function (item) {
          if($(context_object).attr("data-id-attribute") != undefined)
          {
            if($(context_object).attr("data-id-attribute") == "self" && item.length != 0)
            {
              return JSON.stringify(item);
            }
            
            return  item[$(context_object).attr("data-id-attribute")];
          }
          else
          {
            return item.id;
          }
        }

    });
    $(".remote_select2").on("change", function(e) {
      if($(this).attr("data-autosubmit") == 'true')
      {

        $(this).parent().submit();
        preventDefault();
      }

    });
  });

  //Remove the class so this is only classed once...
  $(".remote_select2").removeClass("remote_select2");
  $(".remote_select2").css("display", "")

  


  //Actions for hidden fields
  $('.hidden').hide();
  $('.reveal-hidden').mouseover(function() { $(this).find(".hidden").show() });
  $('.reveal-hidden').mouseout(function() {$(this).find(".hidden").hide() } );

  


  $('.preload-form').click(function() {
    create_preloader();
  })

  $('.preload').click(function() {
    show_preloader();
  })


  

  //Actions for index checkboxes
  $('#check_all_results').click(function() {
      if($(this).is(':checked'))
      {
        $('.result_checkbox').prop('checked', true);
        $('.result_checkbox').prop('disabled', false);
        $('#update_all_from_query_link').slideDown();
        $('#update_all_from_query').val(false);

        $('#update_all_from_page_header').slideUp();
        $('#update_all_from_page_header').slideDown();
      }
      else
      {
        $('.result_checkbox').prop('checked', false);
        $('.result_checkbox').prop('disabled', false);
        $('#update_all_from_query').val(false);
        $('#update_all_from_page_header').slideUp();
        $('#update_all_from_query_header').slideUp();

      }
      if($(".result_checkbox:checked").length > 0)
      {
          $("#result_action_panel").slideDown();
      }
      else
      {
         $("#result_action_panel").slideUp();
      }

   });

  $('#update_all_from_query_link').click(function() {
    $('#update_all_from_query').val(true);
    $('.result_checkbox').prop('disabled', true);
    $('#update_all_from_query_header').slideDown();
    $('#update_all_from_page_header').slideUp();
    if($(".result_checkbox:checked").length > 0)
    {
        $("#result_action_panel").slideDown();
    }
    else
    {
       $("#result_action_panel").slideUp();
    }
  });

  $('#clear_selection').click(function() {
    $('#update_all_from_query').val(false);
    $('#update_all_from_query_header').slideUp();
    $('#update_all_from_page_header').slideUp();
    $('.result_checkbox').prop('checked', false);
    $('.result_checkbox').prop('disabled', false);
    $('#check_all_results').prop('checked', false);
    $("#result_action_panel").slideUp();
  });

  $('.result_checkbox').click(function()
  {
    $('#check_all_results').prop('checked', false);
    $('#update_all_from_query').val(false);
    $('#update_all_from_query_header').slideUp();
    $('#update_all_from_page_header').slideUp();

    if($(".result_checkbox:checked").length > 0)
    {
        $("#result_action_panel").slideDown();
    }
    else
    {
       $("#result_action_panel").slideUp();
    }
  })

  $('.update_multiple_button').click(function(e) {
    if(!e.isDefaultPrevented())
    {
      $('#update_multiple_form').append($("#selection_table").find("input").clone(true,true).hide())
    }
  })

  $('.schedule_tasks_button').click(function(e) {
    if(!e.isDefaultPrevented())
    {
      $('#schedule_tasks_form').append($("#selection_table").find("input").clone(true,true).hide())
    }
  })

  $('.update_multiple_link').click(function(e) {

    $('#update_multiple_form').append($("#selection_table").find("input").clone(true,true).hide())

    $.each($(this).data(), function(index, value) {

      $('<input>').attr({
        type: 'hidden',
        name: camelToSnake(index),
        value: value
      }).appendTo('#update_multiple_form');

    });
    $(this).closest("form").submit();
    return false;

  })




  //Lightboxes
  $('.open_lightbox').click(function() {
    $($(this).parent().find("img")[1]).trigger("click")
  })


  $('.update_jira').click(function() {

    var result_id = $(this).data("result-id");
    // find tex field with this id, get jira tickets
    var tickets = $("#vulnerability_jira_field_" + result_id).val();

    function reverse(s) {
      var o = '';
      for (var i = s.length - 1; i >= 0; i--)
        o += s[i];
      return o;
    }

    var pattern = new RegExp(/\d+-[A-Za-z]+(?!-?[a-zA-Z]{1,10})/);
    var ticket_array;
    //var tickets = "VUL-566,VUL-544,VUL-432"
    if (tickets.includes(',')) {
      try {
        ticket_array = tickets.split(",");
      } catch (err) {
        alert('cannot parse jira tickets');
        return false;
      }

    } else {
      ticket_array = [tickets];
    }
    var i;
    for (i = 0; i < ticket_array.length; i++) {
      if (pattern.test(reverse(ticket_array[i])) === false) {
        alert("invalid ticket: " + ticket_array[i]);
        return false;
      }
    }
    return true;
  })


  //Split buttons
  $('.split_button_submit').click(function(e) {
    if(!e.isDefaultPrevented())
    {
      $(this).after($('<input />')
        .attr('id', 'commit')
        .attr('name', 'commit')
        .attr('type', 'hidden')
        .attr('value', this.text))

      $(this).closest("form").submit();
    }
  })

    $('.split_button_submit > span').click(function(e) {
    e.preventDefault();

  })


  $(".accordion .accordion-navigation button.button.dropdown").click(function(e)
  {
    e.stopImmediatePropagation();
    e.preventDefault();
    Foundation.libs.dropdown.toggle($(e.target))
    //Next lines hangle a bug that causes Foundation to inject Accordion links into the dropdown
    $("#"+$(e.target).data("dropdown")).find("a").each(function(index, entry)
    {
      if(entry.href.indexOf("#accordion_") != -1)
      {
        entry.remove();
      }
    })


  })

  $(".button.add_finding_button").click(function(event) {
    $('#div_' + event.target.id).show();
    event.stopPropagation();
    event.preventDefault();
  });


  


  betterTooltips();
};






$(document).ready(ready);


$(function(){ $(document).foundation(); });
