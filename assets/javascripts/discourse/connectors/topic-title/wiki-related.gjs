<template>
  {{#if @outletArgs.model.wiki_related}}
    <section
      class="wiki-related-card"
      data-wiki-related-card="true"
      aria-labelledby="wiki-related-heading"
    >
      <h3 id="wiki-related-heading">
        {{@outletArgs.model.wiki_related.heading}}
      </h3>
      <ul>
        {{#each @outletArgs.model.wiki_related.links as |link|}}
          <li><a href={{link.url}}>{{link.title}}</a></li>
        {{/each}}
      </ul>
    </section>
  {{/if}}
</template>
