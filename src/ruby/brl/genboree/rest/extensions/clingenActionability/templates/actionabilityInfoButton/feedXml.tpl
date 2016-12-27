<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xml:base="<%= pv( 'feed.xmlBase' ) %>" xml:lang="en" xsi:schemaLocation="http://www.w3.org/2005/Atom KnowledgeResponse.xsd">
  <title type="text"><%= pv( 'feed.title' ) %></title>
  <subtitle type="text"><%= pv( 'feed.subtitle' ) %></subtitle>
  <author>
    <name><%= pv( 'feed.author.name' ) %></name>
    <uri><%= pv( 'feed.author.uri' ) %></uri>
  </author>
  <updated><%= pv( 'feed.updated' ) %></updated>
  <category scheme="mainSearchCriteria.v.c" term="<%= pv( 'feed.category.termC' ) %>"/>
  <category scheme="mainSearchCriteria.v.cs" term="<%= pv( 'feed.category.termCS' ) %>"/>

  <%= render_each( 'feed.actionabilityDocs', :feedEntry ) %>

</feed>
