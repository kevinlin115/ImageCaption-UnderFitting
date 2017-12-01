# python2.7
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import random
import tensorflow as tf


# true captions
tf.flags.DEFINE_string("output_file", None, "Files to which image/pos/neg triplets are saved.")
tf.flags.DEFINE_string("true_captions", None, "Files containing true captions.")
tf.flags.DEFINE_string("proposed_captions", None, "Files containing algorithm proposed captions.")
tf.flags.DEFINE_integer("strategy1", 0, "Number of image/pos/neg triplets generated by strategy1.")
tf.flags.DEFINE_integer("strategy2", 0, "Number of image/pos/neg triplets generated by strategy2.")

FLAGS = tf.flags.FLAGS

if __name__ == "__main__":
  strategy1 = FLAGS.strategy1 
  strategy2 = FLAGS.strategy2 

  true_captions = {}
  proposed_captions = {}
  image_ids = set()
  
  with open(FLAGS.true_captions) as F:
    for line in F:
      image_id, caption, score = map(lambda x: x.strip(), line.split("\t"))
      score = float(score)
      image_ids.add(image_id)
      if image_id not in true_captions:
        true_captions[image_id] = []
      true_captions[image_id].append((score, caption))

  with open(FLAGS.proposed_captions) as F:
    for line in F:
      image_id, caption, score = map(lambda x: x.strip(), line.split("\t"))
      score = float(score)
      assert image_id in image_ids, "unknown image_id %s" % image_id
      if image_id not in proposed_captions:
        proposed_captions[image_id] = []
      proposed_captions[image_id].append((score, caption))

  with open(FLAGS.output_file, "w") as Fo:
    def get_random(l):
      return l[random.randint(0, len(l)-1)]
      
    def get_candidates(image_id, gt, pd, num):
      candidates = []
      loop = int((num + len(gt) - 1) / len(gt))
      for i in range(loop):
        for sp, p in gt:
          for k in xrange(100):
            sn, n = get_random(pd)
            if sn < sp:
              break
          if sn < sp:
            candidates.append((image_id, p, n))
          else:
            raise Exception("cannot find negative sample")
      random.shuffle(candidates)
      return candidates[:num]

    lines = []
    captions_pool = []
    for image_id in image_ids:
      gt = true_captions[image_id]
      pd = proposed_captions[image_id]

      try:
        if strategy1 > 0:
          c1 = get_candidates(image_id, gt, pd, strategy1)
          lines.extend(map(lambda x: "\t".join(x)+"\n", c1))

        pd.sort(reverse=True)
        top_pd = pd[:2]
        other_pd = pd[2:]

        if strategy2 > 0:
          c2 = get_candidates(image_id, top_pd, other_pd, strategy2)
          lines.extend(map(lambda x: "\t".join(x)+"\n", c2))

        if strategy3 > 0:
          # maintain a caption's pool
          captions_pool.extend(pd)
          random.shuffle(captions_pool)
          captions_pool = captions_pool[:1000]
          # get stratefy3 candidates
          c3 = get_candidates(image_id, top_pd, captions_pool, strategy3)
          lines.extend(map(lambda x: "\t".join(x)+"\n", c3))

      except Exception as e:
        print(e)
      finally:
        pass
    
    Fo.writelines(lines)


