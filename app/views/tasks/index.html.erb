<%= javascript_tag do %>
  window.localStorage.setItem('expanded_all_tasks', "false");
  $(document).ready(function () {
    $("#loading").hide();
  });
$(function(){
  $('#expandall_arrow').click(function(){
        $("#loading").show();
    });

  $(document).ajaxStop(function(){
        $("#loading").hide();
    });
    });
<% end %>
<div id="loading" class="loading" style="display:nont">Loading&#8230;</div>
<div id="selection_table">
  <% i = 1 %>
  <% @tasks.sort.each do |group, tasks| %>
    <nav class="tab-bar">
      <section class="tab-bar-section">
        <h1>Group <%= i %></h1>
      </section>
    </nav>
    <% i += 1 %>
    <table>
      <tr>
        <th><%= link_to "&#9658;".html_safe, expandall_tasks_path(), :id => "expandall_arrow", :remote=>true %></th>
        <th></th>
        <th></th>
        <th>Name</th>
        <th>Task Type</th>
        <th>Query</th>
        <th>Last Success</th>
        <th></th>
      </tr>
      <% tasks.partition{|v| v.enabled == true}.flatten.each do |task| %>
        <tr class="<%= "disabled" if task.enabled != true %>">
          <td><%= link_to "&#9658;".html_safe, summary_task_path(task), :id => "summary_icon_#{task.id}", :remote=>true %></td>
          <td><%= check_box_tag "task_ids[]", task.id, false, {:class=>"result_checkbox"} %></td>
          <% status_class = task.metadata.try(:[], "_last_status").to_s.downcase %>
          <% status_class = "classification-" + status_class if status_class.present? %>
          <% if task.metadata.try(:[], "_last_status") %>
            <% message = task.metadata.try(:[], "_last_status").to_s %>
            <% message +=  "<br/>" + h(task.metadata.try(:[], "_last_status_message").to_s) if task.metadata.try(:[], "_last_status_message") %>
            <% message += "<br/>" + link_to("Event #{task.metadata.try(:[], "_last_status_event")}", event_path(task.metadata.try(:[], "_last_status_event"))) if task.metadata.try(:[], "_last_status_event") %>
            <% message +=  "<br/>Last run: " + time_ago_in_words(DateTime.parse(task.metadata.try(:[], "_last_run").to_s)) + " ago" if task.metadata.try(:[], "_last_run")%>
            <% message +=  "<br/>Last success: " + time_ago_in_words(DateTime.parse(task.metadata.try(:[], "_last_successful_run").to_s)) + " ago" if task.metadata.try(:[], "_last_successful_run")%>
            <% if task.metadata.try(:[], "current_events").try(:[], "Error").present? %>
              <% message += search_form_for Event.search, :url=>search_events_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["current_events"]["Error"].first(200).each do |error_event| %>
                  <%= hidden_field_tag 'q[id_in][]', error_event %>
                <% end %>
                <%= link_to 'Current Event Errors: ' + task.metadata.try(:[], "current_events").try(:[], "Error").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "current_events").try(:[], "Warn").present? %>
              <% message += search_form_for Event.search, :url=>search_events_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["current_events"]["Warn"].first(200).each do |warn_event| %>
                  <%= hidden_field_tag 'q[id_in][]', warn_event %>
                <% end %>
                <%= link_to 'Current Event Warnings: ' + task.metadata.try(:[], "current_events").try(:[], "Warn").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "current_results").try(:[], "created").present? %>
              <% message += search_form_for Result.search, :url=>search_results_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["current_results"]["created"].first(200).each do |created_result| %>
                  <%= hidden_field_tag 'q[id_in][]', created_result %>
                <% end %>
                <%= link_to 'Current Results Created: ' + task.metadata.try(:[], "current_results").try(:[], "created").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "current_results").try(:[], "updated").present? %>
              <% message += search_form_for Result.search, :url=>search_results_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["current_results"]["updated"].first(200).each_with_index do |index, updated_result| %>
                  <%= hidden_field_tag 'q[id_in][]', updated_result %>
                <% end %>
                <%= link_to 'Current Results Updated: ' + task.metadata.try(:[], "current_results").try(:[], "updated").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "previous_events").try(:[], "Error").present? %>
              <% message += search_form_for Event.search, :url=>search_events_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["previous_events"]["Error"].first(200).each do |error_event| %>
                  <%= hidden_field_tag 'q[id_in][]', error_event %>
                <% end %>
                <%= link_to 'Previous Event Errors: ' + task.metadata.try(:[], "previous_events").try(:[], "Error").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "previous_events").try(:[], "Warn").present? %>
              <% message += search_form_for Event.search, :url=>search_events_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["previous_events"]["Warn"].first(200).each do |warn_event| %>
                  <%= hidden_field_tag 'q[id_in][]', warn_event %>
                <% end %>
                <%= link_to 'Previous Event Warnings: ' + task.metadata.try(:[], "previous_events").try(:[], "Warn").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "previous_results").try(:[], "created").present? %>
              <% message += search_form_for Result.search, :url=>search_results_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["previous_results"]["created"].first(200).each do |created_result| %>
                  <%= hidden_field_tag 'q[id_in][]', created_result %>
                <% end %>
                <%= link_to 'Previous Results Created: ' + task.metadata.try(:[], "previous_results").try(:[], "created").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
            <% if task.metadata.try(:[], "previous_results").try(:[], "updated").present? %>
              <% message += search_form_for Result.search, :url=>search_results_path, :html => {:target=>'_blank'}, :method=>:post, :authenticity_token => false, id:"search_form" do |f| %>
                <% task.metadata["previous_results"]["updated"].first(200).each do |updated_result| %>
                  <%= hidden_field_tag 'q[id_in][]', updated_result %>
                <% end %>
                <%= link_to 'Previous Results Updated: ' + task.metadata.try(:[], "previous_results").try(:[], "updated").length.to_s, "", {class: "submit_form_link", target: '_blank'} %>
              <% end %>
            <% end %>
          <% end %>
          <td class="<%= status_class %> has-tip bettertooltip" data-tooltip data-options="hover_delay: 500;" aria-haspopup="true"  title="<%= message %>">&nbsp;</td>
          <td><%= link_to task.name, task %></td>
          <td><%= task.task_type_name %></td>
          <td><%= task.query %></td>
          <td><%= time_ago_in_words(DateTime.parse(task.metadata.try(:[], "_last_successful_run").to_s)) + " ago" if task.metadata.try(:[], "_last_successful_run")%></td>
          <td>
            <% if task.enabled %>
              <%= link_to 'Disable', disable_task_path(task), method: :post, class: "button tiny" if can? :disable, task %>
            <% else %>
              <%= link_to 'Enable', enable_task_path(task), method: :post, class: "button tiny" if can? :enable, task %>
            <% end %>
            <%= link_to 'Edit', edit_task_path(task), class: "button tiny" if can? :edit, task %>
            <%= link_to 'Destroy', task, method: :delete, data: { confirm: 'Are you sure?' }, class: "button tiny alert" if can? :destroy, task %></td>
        </tr>
        <tr>
          <td colspan="8" style="padding: 0; margin: 0; border: 0;">
            <div id="summary_<%= task.id %>" style="display:none;"> </div>
          </td>
        </tr>
      <% end %>
    </table>
    <br />
  <% end %>
</div>
<%= link_to 'New Task', new_task_path, class: "button" if can? :create, Task %>
<%= link_to 'Run All Enabled Tasks', run_tasks_path, class: "button alert" if can? :run, Task  %>
<%= content_for :sidebar do %>
  <div class="sidebar">
    <nav class="tab-bar">
      <section class="tab-bar-section">
        <h1>Actions</h1>
      </section>
    </nav>
    <section class="panel sidepanel">
      <%= form_tag bulk_update_tasks_path, method: :post, :id=>"update_multiple_form" do %>
        <dl class="dl-horizontal">
          <dt class="half">Move to:</dt>
          <dd>
            <a href="#" data-dropdown="drop_move" class="button dropdown tiny secondary">Choose group</a><br>
            <ul id="drop_move" data-dropdown-content class="f-dropdown">
              <% groups = Task.select(&:group).map(&:group).uniq.sort.each_with_index.map{|g,i| [g,"Group #{i+1}"]}
            groups << [groups.try(:last).try(:first).to_i+1, "New Group"]
           %>
              <% groups.each do |group| %>
                <li><%= link_to group.last, "#", method: :post, class: "update_multiple_link", data: {commit: "Change Group", group_id: group.first} %></li>
              <% end %>
            </ul>
          </dd>
        </dl>
        <% if can? :enable, Task %>
          <%= submit_tag "Enable", :method=>:post, :class=>"button small update_multiple_button" %>
        <% end %>
        <% if can? :disable, Task %>
          <%= submit_tag "Disable", :method=>:post, :class=>"button small update_multiple_button" %>
        <% end %>
        <% if can? :run, Task %>
          <%= submit_tag "Run", :method=>:post, :class=>"button small update_multiple_button" %>
        <% end %>
        <% if can? :destroy, Task %>
          <%= submit_tag "Delete", :method=>:delete, :class=>"button small alert update_multiple_button", data: {:confirm=>"Are you sure you want to delete these tasks?"} %>
        <% end %>
      <% end %>
    </section>
  </div>
<% end %>
