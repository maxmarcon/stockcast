<template>
  <b-card>
    <template slot="header">
      <message-bar id="errorBar" ref="errorBar" variant="danger" :seconds=10></message-bar>
      <b-form>
        <b-form-row>
          <b-col md="4">
            <b-form-group label="Stocks:"
                          labe-for="stocks">
              <vue-tags-input
                id="stocks"
                v-model="tag"
                :tags="tags"
                @tags-changed="tagsChanged"
                :avoidAddingDuplicates="true"
                :autocomplete-items="autocompleteItems"
                :max-tags="10"
                :maxlength="50"
                :add-only-from-autocomplete="true"
                placeholder="Search by name, ticker, or ISIN">
              </vue-tags-input>
            </b-form-group>
          </b-col>
          <b-col md="auto">
            <b-form-group label="From:"
                          labe-for="date-from">
              <b-form-datepicker id="date-from"></b-form-datepicker>
            </b-form-group>
          </b-col>
          <b-col md="auto">
            <b-form-group label="To:"
                          labe-for="date-to">
              <b-form-datepicker id="date-to"></b-form-datepicker>
            </b-form-group>
          </b-col>
        </b-form-row>
      </b-form>
    </template>
    Money here $$$
  </b-card>
</template>
<script>
  export default {
    data: () => ({
      tag: '',
      tags: [],
      autocompleteItems: []
    }),
    methods: {
      tagsChanged() {
      }
    }
  }
</script>


