# siinatra35.github.io

A cybersecurity blog (malware analysis, Hack The Box writeups, research notes), built with [Jekyll](https://jekyllrb.com/) and hosted on GitHub Pages.

## Writing a post

1. Create a file in `_posts/` named `YYYY-MM-DD-title-of-post.md`.
2. Add front matter:

   ```yaml
   ---
   title: "HTB: MachineName"
   description: "Short summary shown on cards."
   categories: [htb]        # malware | htb | research | notes
   tags: [linux, web]
   difficulty: Easy         # optional, shown on the card
   box:                     # optional info table at the top of the post
     OS: Linux
     Difficulty: Easy
   ---
   ```

3. Write in Markdown, then commit and push. GitHub builds the site automatically.

Templates for HTB writeups and malware reports are in `_drafts/`. Copy one into `_posts/` with a date in the filename.

Categories and their labels are set in `_config.yml` under `category_labels`.

## Preview locally

Needs Ruby. Then:

```bash
bundle install
bundle exec jekyll serve --drafts
```

Open http://localhost:4000.
