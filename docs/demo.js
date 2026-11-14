// The Shaman bar demo: the same rules as the addon's UI/ImbueButton.lua,
// UI/FireNovaButton.lua and UI/Hints.lua, with demo values.
//   * Imbue button: one press, out of combat, applies the recommended imbue
//     (Rockbiter Weapon before 30, Windfury Weapon for Enhancement after the
//     Nov 10/11 hotfix). Imbues last 60 minutes; under 5 minutes it says "refresh soon".
//   * Fire Nova button: lit only while a Fire totem is down (Fire Nova erupts at
//     your Fire totem; Fire Nova Totem is removed in Forever).
//   * Shield hint: orbs left, "refresh me" at zero. A hint, never a button.
//   * Totems hint: nudges about missing elements only in combat (dropping totems
//     with nothing to fight wastes mana). A hint, never a button.
// One press, one cast. Nothing here casts on its own.
(() => {
  const root = document.querySelector("#shaman-demo");
  if (!root) return;
  const ICON = (name) => `https://render.worldofwarcraft.com/us/icons/56/${name}.jpg`;

  const IMBUES = {
    rockbiter: { spell: "Rockbiter Weapon", icon: ICON("spell_nature_rockbiter") },
    windfury: { spell: "Windfury Weapon", icon: ICON("spell_nature_cyclone") },
  };
  const NOVA_ICON = ICON("spell_fire_sealoffire");
  const SHIELD = { spell: "Lightning Shield", icon: ICON("spell_nature_lightningshield"), orbs: 3 };
  // Elements in the order the class quests unlock them (Earth 4, Fire 10, Water 20, Air 30).
  const ELEMENTS = [
    { name: "Earth", unlock: 4, icon: ICON("spell_nature_earthbindtotem") },
    { name: "Fire", unlock: 10, icon: ICON("spell_fire_searingtotem") },
    { name: "Water", unlock: 20, icon: ICON("spell_nature_manaregentotem") },
    { name: "Air", unlock: 30, icon: ICON("spell_nature_windfury") },
  ];
  const SOON = 5; // minutes: "refresh soon" (addon choice)

  let level = 20;
  let imbue = null; // { key, left } in minutes
  let orbs = 0;
  let combat = false;
  let down = new Set();
  let flash = null;

  const list = root.querySelector(".elements");
  const imbueBtn = root.querySelector(".imbue-btn");
  const novaBtn = root.querySelector(".nova-btn");
  const status = root.querySelector(".demo-status");
  const shieldHint = root.querySelector(".shield-hint");
  const totemHint = root.querySelector(".totem-hint");
  const combatRow = root.querySelector(".demo-combat");
  const combatBtn = root.querySelector(".combat-toggle");

  const recommended = () => (level >= 30 ? "windfury" : "rockbiter");
  const unlocked = () => ELEMENTS.filter((e) => level >= e.unlock);

  function say(title, text) {
    status.innerHTML = "<b></b><span></span>";
    status.querySelector("b").textContent = title;
    status.querySelector("span").textContent = text;
  }

  function render() {
    list.innerHTML = "";
    for (const e of ELEMENTS) {
      const open = level >= e.unlock;
      const li = document.createElement("li");
      const b = document.createElement("button");
      b.type = "button";
      b.className = "el-slot " + e.name.toLowerCase() + (down.has(e.name) ? " down" : "") + (open ? "" : " locked") + (flash === e.name ? " flash" : "");
      b.disabled = !open;
      b.innerHTML = `<img alt=""><b></b><span></span>`;
      b.querySelector("img").src = e.icon;
      b.querySelector("b").textContent = e.name;
      b.querySelector("span").textContent = !open ? `level ${e.unlock}` : down.has(e.name) ? "down" : "none";
      b.setAttribute("aria-pressed", String(down.has(e.name)));
      b.setAttribute("aria-label", open ? `${e.name} totem: ${down.has(e.name) ? "down, click to pick up" : "none, click to drop"}` : `${e.name}: unlocks at level ${e.unlock}`);
      b.addEventListener("click", () => toggle(e.name));
      li.append(b);
      list.append(li);
    }
    flash = null;

    // Imbue button
    const rec = IMBUES[recommended()];
    imbueBtn.style.setProperty("--icon", `url("${rec.icon}")`);
    imbueBtn.disabled = combat;
    imbueBtn.querySelector(".left").textContent = imbue ? `${imbue.left}m` : "";
    imbueBtn.classList.toggle("soon", !!imbue && imbue.left <= SOON);
    imbueBtn.setAttribute("aria-label", combat ? "Imbue button: waits until the fight ends" : `Apply ${rec.spell}`);

    // Fire Nova button
    const fire = down.has("Fire");
    novaBtn.style.setProperty("--icon", `url("${NOVA_ICON}")`);
    novaBtn.classList.toggle("dim", !fire);
    novaBtn.hidden = level < 10;
    novaBtn.setAttribute("aria-label", fire ? "Fire Nova: ready" : "Fire Nova: no Fire totem");

    // Shield hint
    shieldHint.classList.toggle("warn", orbs === 0);
    shieldHint.innerHTML = `<img alt=""><div><b></b><span></span></div>`;
    shieldHint.querySelector("img").src = SHIELD.icon;
    shieldHint.querySelector("b").textContent = "Shield";
    shieldHint.querySelector("span").textContent = orbs ? `${SHIELD.spell}: ${orbs} orb${orbs === 1 ? "" : "s"} left` : "refresh me";

    // Totems hint
    const missing = unlocked().filter((e) => !down.has(e.name)).map((e) => e.name);
    totemHint.classList.toggle("warn", combat && missing.length > 0);
    totemHint.innerHTML = `<img alt=""><div><b></b><span></span></div>`;
    totemHint.querySelector("img").src = ELEMENTS[0].icon;
    totemHint.querySelector("b").textContent = "Totems";
    totemHint.querySelector("span").textContent = !combat
      ? "quiet between pulls"
      : missing.length ? `missing: ${missing.join(", ")}` : "all elements down";

    combatRow.classList.toggle("on", combat);
    combatRow.querySelector("span").textContent = combat ? "In combat: the imbue button waits." : "Out of combat.";
    combatBtn.textContent = combat ? "Leave combat" : "Pull a mob";
  }

  function idle() {
    const rec = IMBUES[recommended()];
    if (combat) say("In combat", "The imbue button keeps its spell until the fight ends. Imbue between pulls.");
    else if (!imbue) say(`Next: ${rec.spell}`, "Press the imbue button or I.");
    else if (imbue.key !== recommended()) say(`Recommended: ${rec.spell}`, `You have ${IMBUES[imbue.key].spell} on. Press to switch.`);
    else if (imbue.left <= SOON) say("Refresh soon", `${rec.spell}: ${imbue.left} minutes left.`);
    else say(`${rec.spell} is on`, `${imbue.left} minutes left.`);
  }

  function applyImbue() {
    if (combat) return;
    imbue = { key: recommended(), left: 60 };
    render();
    say(`+ ${IMBUES[imbue.key].spell}`, "Highest rank you know, 60 minutes.");
    check();
  }

  function nova() {
    if (level < 10) return;
    if (!down.has("Fire")) { say("No Fire totem", "Fire Nova erupts at your Fire totem. Drop one first."); return; }
    flash = "Fire";
    render();
    say("+ Fire Nova", "Erupts at your Fire totem.");
  }

  function toggle(name) {
    if (down.has(name)) down.delete(name); else { down.add(name); flash = name; }
    render();
    if (name === "Fire") say(down.has("Fire") ? "Fire totem down" : "Fire totem gone", down.has("Fire") ? "The Fire Nova button lights up." : "The Fire Nova button dims.");
    else idle();
    check();
  }

  function check() {
    const all = unlocked().every((e) => down.has(e.name));
    if (all && imbue && imbue.key === recommended() && orbs > 0 && window.tazusAchieve) {
      window.tazusAchieve(`aligned-${level}`, "Elements Aligned", "Imbue on, shield up, every totem down.", ICON("spell_nature_bloodlust"), 10);
    }
  }

  imbueBtn.addEventListener("click", applyImbue);
  novaBtn.addEventListener("click", nova);
  combatBtn.addEventListener("click", () => {
    combat = !combat;
    if (!combat) down = new Set(); // totems expire or get left behind after a fight
    render();
    idle();
  });
  root.querySelector(".wait-btn").addEventListener("click", () => {
    if (imbue) {
      imbue.left -= 20;
      if (imbue.left <= 0) imbue = null;
    }
    render();
    if (imbue || combat) idle(); else say("Imbue faded", "Press the imbue button to put it back.");
  });
  root.querySelector(".hit-btn").addEventListener("click", () => {
    if (orbs > 0) orbs -= 1;
    render();
    say(orbs ? "Zap" : "Shield gone", orbs ? `${orbs} orb${orbs === 1 ? "" : "s"} left.` : "The Shield hint says refresh me.");
  });
  root.querySelector(".shield-btn").addEventListener("click", () => {
    orbs = SHIELD.orbs;
    render();
    say(`+ ${SHIELD.spell}`, "Cast from your own action bar. The hint just counts.");
    check();
  });
  root.querySelectorAll('input[name="demo-level"]').forEach((r) =>
    r.addEventListener("change", () => {
      level = Number(r.value);
      for (const e of ELEMENTS) if (level < e.unlock) down.delete(e.name);
      render();
      idle();
    }),
  );
  root.addEventListener("keydown", (e) => {
    if (e.target.tagName === "INPUT") return;
    if (e.key === "i" || e.key === "I") { e.preventDefault(); applyImbue(); }
    if (e.key === "n" || e.key === "N") { e.preventDefault(); nova(); }
  });

  render();
  idle();
})();
