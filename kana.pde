import java.util.Map.Entry;

final int PICK_SAMPLES = 10;
final float SCORE_CORRECT = 5;
final float SCORE_INCORRECT = -10;

ArrayList<String> kana = new ArrayList<String>();
ArrayList<String> romaji = new ArrayList<String>();
float[] score;

int previous_index;
int index;
boolean reveal_romaji;

String typed_romaji = "";

int total = 0;

void setup() {
  size(640, 640);

  //----------------------------------------------HIRAGANA ONLY---
  //String[] lines = loadStrings("hiragana.txt");

  //----------------------------------------------KATAKANA ONLY---
  //String[] lines = loadStrings("katakana.txt");

  //----------------------------------------------BOTH------------
  String[] lines = concat(loadStrings("katakana.txt"), loadStrings("hiragana.txt"));

  for (String l : lines) {
    if (!l.isEmpty()) {
      String[] split = l.split("\\s+");
      if (split.length >= 2) {
        kana.add(split[0]);
        romaji.add(split[1]);
      } else {
        println("Invalid line in chars.txt: \"" + l + "\"");
      }
    }
  }
  score = new float[kana.size()];
  for (int i = 0; i < score.length; i++) {
    score[i] = 0;
  }
  Table score_table = loadTable("saved_scores.csv","header");
  if (score_table != null) {
    for (int i = 0; i < score_table.getRowCount(); i++) {
      TableRow r = score_table.getRow(i);
      String k = r.getString("Kana");
      float s = r.getFloat("Score");
      int ki = kana.indexOf(k);
      if(ki >= 0) {
        score[ki] = s;
      }
    }
  }

  Runtime.getRuntime().addShutdownHook(new Thread() {
    public void run() {
      Table score_table = new Table();
      score_table.addColumn("Kana");
      score_table.addColumn("Score");
      for (int i = 0; i < score.length; i++) {
        TableRow r = score_table.addRow();
        r.setString("Kana", kana.get(i));
        r.setFloat("Score", score[i]);
      }
      saveTable(score_table, "saved_scores.csv");
    }
  }
  );

  next_kana();
  previous_index = index;

  fill(0);
  //textFont(createFont("mplus-1p-regular.ttf",12));
}

void draw() {
  background(0xff);

  textAlign(LEFT, TOP);
  text("Total: " + total, 2, 0);

  textAlign(RIGHT, TOP);
  text(int(score[index]), width-2, 0);

  textAlign(CENTER, CENTER);
  translate(220, 200);
  scale(25);
  text(kana.get(index), 0, 0);

  resetMatrix();
  translate(320, 500);
  scale(10);

  if (!reveal_romaji) text(typed_romaji, 0, 3);

  if (reveal_romaji) {
    resetMatrix();
    translate(320, 500);
    scale(10);
    text(romaji.get(index), 0, 3);
  }

  score[index]-=deltatime();
}

void keyPressed() {

  if ('a' <= key && key <= 'z') {
    typed_romaji += key;
  } else if (key == '\b') {
    if (typed_romaji.length() > 0) {
      typed_romaji = typed_romaji.substring(0, typed_romaji.length()-1);
    }
  }
  check_typed();

  if (key == ' ') {
    if (!reveal_romaji) {
      reveal_romaji = true;
    } else {
      reveal_romaji = false;
    }
  }
}
void next_kana() {
  previous_index = index;
  while (index == previous_index) {
    index = weighted_pick();
  }
  reveal_romaji = false;
  typed_romaji = "";

  total++;
}

int weighted_pick() {
  int pick = int(random(0, score.length));
  for (int unu = 0; unu < PICK_SAMPLES; unu++) {
    int p = int(random(0, score.length));
    if (score[p] == 0 || score[p] < score[pick]) pick = p;
  }
  return pick;
}

void check_typed() {
  if (typed_romaji.equals(romaji.get(index))) {
    score[index]+=SCORE_CORRECT;
    next_kana();
  } else {
    if (!(typed_romaji.equals("n") && romaji.get(index).charAt(0) == 'n')) {
      for (int i = 0; i < romaji.size(); i++) {
        if (typed_romaji.equals(romaji.get(i))) {
          score[index]+=SCORE_INCORRECT;
          typed_romaji = "";
        }
      }
    }
  }
}

int prev_time = 0;
float deltatime() {
  int dt = millis() - prev_time;
  prev_time += dt;
  return dt/1000.0;
}
