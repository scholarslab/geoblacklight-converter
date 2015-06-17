# Geoblacklight Scripts

To regenerate the `JSON` for Solr, run the `iso2json.rb` script and
point it to an updated version of the OpenGeoMetadata repository for
`edu.virginia`. You can watch what's going on with the `-v` flag. When
you're done, you can then run `post.sh` to send it to the Solr server.


## Older Notes
First, run the clean script:

```
$ clean.sh
```

When you're done (and Solr is running)

```
$ post.sh
```

## Notes

Need to iterate over each `gmd:onLine` and create new derivative
records for each layer. Each record will need to have its metadata
massaged for titles, etc. Keywords will need to be removed...


