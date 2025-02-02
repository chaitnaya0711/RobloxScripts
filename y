<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Ultra Advanced Battle Simulation 3D – Optimized</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; font-family: Arial, sans-serif; }
    body {
      background: #1a1a1a;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 15px;
    }
    #stats {
      position: fixed;
      top: 10px;
      left: 10px;
      color: white;
      background: rgba(0,0,0,0.7);
      padding: 10px;
      border-radius: 5px;
      font-size: 14px;
      z-index: 10;
    }
    #controls {
      position: fixed;
      bottom: 10px;
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      z-index: 10;
    }
    button {
      padding: 8px 16px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      transition: all 0.3s;
      font-weight: 600;
    }
    button:hover {
      transform: translateY(-2px);
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    }
    .blue-btn { background: #0066ff; color: white; }
    .red-btn { background: #ff3333; color: white; }
    .control-btn { background: #666; color: white; }
    .reset-btn { background: #444; color: white; }
    #camera-controls {
      position: fixed;
      top: 50%;
      right: 10px;
      transform: translateY(-50%);
      display: flex;
      flex-direction: column;
      gap: 10px;
      z-index: 10;
    }
    .camera-btn {
      background: #444;
      color: white;
      padding: 12px;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      user-select: none;
      font-size: 20px;
    }
    #camera-mode {
      position: fixed;
      top: 10px;
      right: 10px;
      display: flex;
      gap: 10px;
    }
    .mode-btn {
      background: #444;
      color: white;
      padding: 8px 16px;
      border-radius: 4px;
    }
    .active {
      background: #666;
    }
  </style>
</head>
<body>
  <div id="stats">
    <div>Blue Army: <span id="blueCount">0</span></div>
    <div>Red Army: <span id="redCount">0</span></div>
    <div>Battle Time: <span id="battleTime">0:00</span></div>
  </div>
  
  <div id="controls">
    <button class="blue-btn" onclick="addBlueArmy('infantry')">Blue Infantry</button>
    <button class="blue-btn" onclick="addBlueArmy('archer')">Blue Archers</button>
    <button class="blue-btn" onclick="addBlueArmy('cavalry')">Blue Cavalry</button>
    <button class="blue-btn" onclick="addBlueArmy('siege')">Blue Siege</button>
    <button class="red-btn" onclick="addRedArmy('infantry')">Red Infantry</button>
    <button class="red-btn" onclick="addRedArmy('archer')">Red Archers</button>
    <button class="red-btn" onclick="addRedArmy('cavalry')">Red Cavalry</button>
    <button class="red-btn" onclick="addRedArmy('siege')">Red Siege</button>
    <button class="control-btn" onclick="toggleFormation()">Toggle Formation</button>
    <button class="control-btn" onclick="toggleInfiniteSpawn()">Toggle Auto-Spawn</button>
    <button class="control-btn" onclick="toggleTactics()">Toggle Advanced Tactics</button>
    <button class="reset-btn" onclick="resetBattlefield()">Reset</button>
  </div>

  <div id="camera-controls">
    <div class="camera-btn" id="zoom-in">+</div>
    <div class="camera-btn" id="zoom-out">-</div>
    <div class="camera-btn" id="move-up">↑</div>
    <div class="camera-btn" id="move-down">↓</div>
    <div class="camera-btn" id="move-left">←</div>
    <div class="camera-btn" id="move-right">→</div>
  </div>
  
  <div id="camera-mode">
    <button class="mode-btn active" onclick="setCameraMode('eagle')">Eagle Eye</button>
    <button class="mode-btn" onclick="setCameraMode('spectator')">Spectator</button>
    <button class="mode-btn" onclick="setCameraMode('free')">Free Cam</button>
  </div>

  <!-- Load three.js -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  
  <script>
  // ---------- GLOBALS & INITIALIZATION ----------
  let scene, camera, renderer, clock;
  const canvasWidth = 1200, canvasHeight = 800;
  let units = [];  // simulation objects
  let terrain = [];
  let formationActive = false;
  let infiniteSpawn = false;
  let advancedTacticsEnabled = false;
  let lastSpawnTime = 0;
  let battleStartTime = Date.now();

  // Camera control variables
  let cameraMode = 'eagle';
  let targetUnit = null;
  let cameraRotation = 0;
  let cameraDistance = 1000;
  const MIN_DISTANCE = 100, MAX_DISTANCE = 2000;
  
  // ----- Instanced Mesh Groups for units ----- 
  // Each key has a structure { mesh, count, max }.
  const unitGroups = {
    "blue_infantry": { mesh: null, count: 0, max: 2000 },
    "blue_archer": { mesh: null, count: 0, max: 2000 },
    "blue_cavalry": { mesh: null, count: 0, max: 2000 },
    "blue_siege": { mesh: null, count: 0, max: 2000 },
    "red_infantry": { mesh: null, count: 0, max: 2000 },
    "red_archer": { mesh: null, count: 0, max: 2000 },
    "red_cavalry": { mesh: null, count: 0, max: 2000 },
    "red_siege": { mesh: null, count: 0, max: 2000 }
  };
  // A single dummy object for matrix updates
  const dummy = new THREE.Object3D();

  // A simple pool for projectiles
  const projectilePool = [];
  
  // ---------- INITIALIZE THREE.JS & INSTANCED MESHES ----------
  function initThree() {
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x1a1a1a);
    
    camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 1, 5000);
    camera.position.set(canvasWidth/2, cameraDistance, canvasHeight/2);
    camera.lookAt(new THREE.Vector3(canvasWidth/2, 0, canvasHeight/2));
    
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);
    
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
    scene.add(ambientLight);
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.7);
    directionalLight.position.set(0, 1000, 500);
    scene.add(directionalLight);
    
    // Ground
    const groundGeo = new THREE.PlaneGeometry(canvasWidth, canvasHeight);
    const groundMat = new THREE.MeshPhongMaterial({color: 0x333333});
    const ground = new THREE.Mesh(groundGeo, groundMat);
    ground.rotation.x = -Math.PI/2;
    ground.position.set(canvasWidth/2, 0, canvasHeight/2);
    scene.add(ground);
    
    clock = new THREE.Clock();
    
    // Create instanced meshes for each unit group.
    for (let key in unitGroups) {
      let team = key.split('_')[0]; 
      let type = key.split('_')[1];
      let geometry, material;
      // Use simple low-poly geometries (they are reused for all instances)
      switch (type) {
        case 'archer':
          geometry = new THREE.BoxGeometry(10, 10, 10);
          break;
        case 'cavalry':
          geometry = new THREE.ConeGeometry(8, 24, 4);
          break;
        case 'siege':
          geometry = new THREE.BoxGeometry(12, 12, 12);
          break;
        default: // infantry
          geometry = new THREE.SphereGeometry(6, 16, 16);
      }
      // Base color per team
      const baseColor = team === 'red' ? 0xff3333 : 0x0066ff;
      material = new THREE.MeshPhongMaterial({ color: baseColor });
      
      const imesh = new THREE.InstancedMesh(geometry, material, unitGroups[key].max);
      imesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      scene.add(imesh);
      unitGroups[key].mesh = imesh;
    }
  }
  
  // ---------- TERRAIN CLASS ----------
  class Terrain {
    constructor(x, z, type) {
      this.x = x; this.z = z; this.type = type;
      this.radius = 40;
      this.mesh = this.createMesh();
      scene.add(this.mesh);
    }
    createMesh() {
      const geometry = new THREE.CircleGeometry(this.radius, 32);
      let material;
      switch(this.type) {
        case 'hill':
          material = new THREE.MeshBasicMaterial({ color: 0x8B4513, transparent: true, opacity: 0.3 });
          break;
        case 'forest':
          material = new THREE.MeshBasicMaterial({ color: 0x228B22, transparent: true, opacity: 0.3 });
          break;
        case 'water':
          material = new THREE.MeshBasicMaterial({ color: 0x00008B, transparent: true, opacity: 0.3 });
          break;
      }
      const mesh = new THREE.Mesh(geometry, material);
      mesh.rotation.x = -Math.PI/2;
      mesh.position.set(this.x, 0.1, this.z);
      return mesh;
    }
    affect(unit) {
      switch(this.type) {
        case 'hill':
          if (unit.type === 'archer' || unit.type === 'siege') {
            unit.range *= 1.2;
          }
          break;
        case 'forest':
          if (unit.type === 'archer') { unit.range *= 0.8; }
          if (unit.type === 'cavalry') { unit.speed *= 0.8; }
          break;
        case 'water':
          unit.speed *= 0.7;
          break;
      }
    }
  }
  
  // ---------- UNIT CLASS (using instanced meshes) ----------
  class Unit {
    constructor(team, type, x, z) {
      this.team = team;
      this.type = type;
      this.x = x;
      this.z = z;
      this.targetX = x;
      this.targetZ = z;
      this.health = 100;
      this.maxHealth = 100;
      this.lastAttack = 0;
      this.inFormation = false;
      this.vx = 0; this.vz = 0;
      this.experience = 0;
      this.morale = 100;
      this.stamina = 100;
      this.baseStats = {};
      
      // Set stats based on type
      switch(type) {
        case 'archer':
          this.radius = 5;
          this.baseStats = { speed: 1.2, damage: 4, range: 150, attackSpeed: 0.8, armor: 2 };
          break;
        case 'cavalry':
          this.radius = 8;
          this.baseStats = { speed: 2.5, damage: 8, range: 20, attackSpeed: 1.5, armor: 4 };
          this.health = this.maxHealth = 120;
          break;
        case 'siege':
          this.radius = 10;
          this.baseStats = { speed: 0.5, damage: 15, range: 200, attackSpeed: 0.3, armor: 8 };
          this.health = this.maxHealth = 150;
          break;
        default:
          this.radius = 6;
          this.baseStats = { speed: 1.8, damage: 6, range: 15, attackSpeed: 1.2, armor: 5 };
      }
      Object.assign(this, this.baseStats);
      
      // Instead of creating a mesh, assign an instance index from the instanced mesh group.
      const key = team + "_" + type;
      const group = unitGroups[key];
      this.instanceIndex = group.count;
      group.count++;
      this.groupKey = key;
      
      // Initial update of the instanced matrix
      this.updateMatrix();
    }
    
    // Update the dummy object and set the matrix for our instance.
    updateMatrix() {
      dummy.position.set(this.x, this.getY(), this.z);
      dummy.rotation.y = 0; // Could be set based on movement direction
      dummy.scale.set(1, 1, 1);
      dummy.updateMatrix();
      unitGroups[this.groupKey].mesh.setMatrixAt(this.instanceIndex, dummy.matrix);
    }
    
    getY() {
      // Adjust height based on type
      if (this.type === 'cavalry') return 8;
      if (this.type === 'siege') return 10;
      if (this.type === 'archer') return 5;
      return 6;
    }
    
    calculateStats() {
      const expBonus = 1 + (this.experience / 1000);
      this.damage = this.baseStats.damage * expBonus;
      this.attackSpeed = this.baseStats.attackSpeed * expBonus;
      const moraleMultiplier = this.morale / 100;
      this.speed = this.baseStats.speed * moraleMultiplier;
      const staminaMultiplier = 0.5 + (this.stamina / 200);
      this.damage *= staminaMultiplier;
      this.speed *= staminaMultiplier;
    }
    
    updateMorale(allies, enemies) {
      const nearbyAllies = allies.filter(u => Math.hypot(u.x - this.x, u.z - this.z) < 100).length;
      const nearbyEnemies = enemies.filter(u => Math.hypot(u.x - this.x, u.z - this.z) < 100).length;
      if (nearbyAllies > nearbyEnemies) {
        this.morale = Math.min(100, this.morale + 0.1);
      } else if (nearbyEnemies > nearbyAllies) {
        this.morale = Math.max(20, this.morale - 0.2);
      }
      if (this.health < this.maxHealth * 0.3) {
        this.morale = Math.max(20, this.morale - 0.1);
      }
    }
    
    decideTactics(allies, enemies, terrainArr) {
      if (!advancedTacticsEnabled) return;
      const nearestEnemy = this.findNearestEnemy(enemies);
      if (!nearestEnemy) return;
      if (this.health < this.maxHealth * 0.3 && this.morale < 50) {
        this.retreat(allies);
        return;
      }
      if (this.inFormation) {
        this.maintainFormation(allies);
        return;
      }
      switch(this.type) {
        case 'archer':
          this.archerTactics(nearestEnemy, allies, terrainArr);
          break;
        case 'cavalry':
          this.cavalryTactics(nearestEnemy, allies, enemies);
          break;
        case 'siege':
          this.siegeTactics(nearestEnemy, allies);
          break;
        default:
          this.infantryTactics(nearestEnemy, allies, enemies);
      }
    }
    
    archerTactics(nearestEnemy, allies, terrainArr) {
      const nearbyHills = terrainArr.filter(t => 
        t.type === 'hill' && Math.hypot(t.x - this.x, t.z - this.z) < 200);
      if (nearbyHills.length > 0) {
        const hill = nearbyHills[0];
        this.targetX = hill.x;
        this.targetZ = hill.z;
      }
      const distToEnemy = Math.hypot(nearestEnemy.x - this.x, nearestEnemy.z - this.z);
      if (distToEnemy < this.range * 0.7) {
        this.retreat(allies);
      }
    }
    
    cavalryTactics(nearestEnemy, allies, enemies) {
      const isolatedEnemies = enemies.filter(e => 
        enemies.filter(other => Math.hypot(other.x - e.x, other.z - e.z) < 50).length < 3
      );
      if (isolatedEnemies.length > 0) {
        const target = isolatedEnemies[0];
        this.targetX = target.x;
        this.targetZ = target.z;
      }
    }
    
    siegeTactics(nearestEnemy, allies) {
      const infantryAllies = allies.filter(a => a.type === 'infantry');
      if (infantryAllies.length > 0) {
        const frontLine = infantryAllies.reduce((acc, unit) => {
          return { x: acc.x + unit.x, z: acc.z + unit.z };
        }, { x: 0, z: 0 });
        frontLine.x /= infantryAllies.length;
        frontLine.z /= infantryAllies.length;
        const angle = Math.atan2(nearestEnemy.z - frontLine.z, nearestEnemy.x - frontLine.x);
        this.targetX = frontLine.x - Math.cos(angle) * 100;
        this.targetZ = frontLine.z - Math.sin(angle) * 100;
      }
    }
    
    infantryTactics(nearestEnemy, allies, enemies) {
      const nearbyAllies = allies.filter(a => Math.hypot(a.x - this.x, a.z - this.z) < 50);
      const nearbyEnemies = enemies.filter(e => Math.hypot(e.x - this.x, e.z - this.z) < 50);
      if (nearbyEnemies.length > nearbyAllies.length * 1.5) {
        this.formShieldWall(nearbyAllies);
      }
    }
    
    formShieldWall(allies) {
      if (allies.length < 2) return;
      const avgPos = allies.reduce((acc, unit) => ({
        x: acc.x + unit.x / allies.length,
        z: acc.z + unit.z / allies.length
      }), { x: 0, z: 0 });
      const spacing = 15;
      const index = allies.indexOf(this);
      this.targetX = avgPos.x + (index - allies.length/2) * spacing;
      this.targetZ = avgPos.z;
    }
    
    retreat(allies) {
      const safeAllies = allies.filter(a => 
        a.health > a.maxHealth * 0.5 &&
        Math.hypot(a.x - this.x, a.z - this.z) > 100
      );
      if (safeAllies.length > 0) {
        const avgPos = safeAllies.reduce((acc, unit) => ({
          x: acc.x + unit.x / safeAllies.length,
          z: acc.z + unit.z / safeAllies.length
        }), { x: 0, z: 0 });
        this.targetX = avgPos.x;
        this.targetZ = avgPos.z;
      }
    }
    
    findNearestEnemy(enemies) {
      let nearest = null, minDist = Infinity;
      enemies.forEach(enemy => {
        if (enemy.health <= 0) return;
        const dist = Math.hypot(enemy.x - this.x, enemy.z - this.z);
        if (dist < minDist) { minDist = dist; nearest = enemy; }
      });
      return nearest;
    }
    
    update(allies, enemies, terrainArr, time) {
      if (this.health <= 0) return;
      this.calculateStats();
      this.updateMorale(allies, enemies);
      
      // Adjust stamina based on movement
      if (Math.hypot(this.vx, this.vz) < 0.1) {
        this.stamina = Math.min(100, this.stamina + 0.1);
      } else {
        this.stamina = Math.max(20, this.stamina - 0.05);
      }
      this.vx = 0; this.vz = 0;
      
      // Apply terrain effects
      terrainArr.forEach(t => {
        if (Math.hypot(t.x - this.x, t.z - this.z) < t.radius) {
          t.affect(this);
        }
      });
      
      this.decideTactics(allies, enemies, terrainArr);
      
      // If in formation, move toward target position
      if (this.inFormation) {
        let dx = this.targetX - this.x, dz = this.targetZ - this.z;
        let dist = Math.hypot(dx, dz);
        if (dist > 1) {
          this.vx += (dx / dist) * this.speed;
          this.vz += (dz / dist) * this.speed;
        }
      }
      
      // Simple separation from other units (only pairwise check here)
      const allUnits = [...allies, ...enemies];
      allUnits.forEach(other => {
        if (other !== this && other.health > 0) {
          let dx = other.x - this.x, dz = other.z - this.z;
          let dist = Math.hypot(dx, dz);
          const minDist = this.radius + other.radius + 5;
          if (dist < minDist) {
            let angle = Math.atan2(dz, dx);
            let force = (minDist - dist) / minDist;
            this.vx -= Math.cos(angle) * force;
            this.vz -= Math.sin(angle) * force;
          }
        }
      });
      
      // Engage enemy if possible
      let target = this.findNearestEnemy(enemies);
      if (target) {
        let dx = target.x - this.x, dz = target.z - this.z;
        let dist = Math.hypot(dx, dz);
        if (this.type === 'archer' || this.type === 'siege') {
          const optimalRange = this.range * 0.7;
          if (dist < optimalRange) {
            this.vx -= (dx / dist) * this.speed;
            this.vz -= (dz / dist) * this.speed;
          } else if (dist > this.range) {
            this.vx += (dx / dist) * this.speed;
            this.vz += (dz / dist) * this.speed;
          }
        } else {
          if (dist > this.range) {
            this.vx += (dx / dist) * this.speed;
            this.vz += (dz / dist) * this.speed;
          }
        }
  
        if (dist <= this.range && (time - this.lastAttack) >= (1000 / this.attackSpeed)) {
          let damage = this.damage;
          if (Math.random() < this.experience / 1000) { damage *= 1.5; }
          damage = Math.max(1, damage - target.armor);
          damage *= this.morale / 100;
          target.health = Math.max(0, target.health - damage);
          this.lastAttack = time;
          this.experience = Math.min(100, this.experience + 0.1);
          drawProjectile(this.x, this.z, target.x, target.z, this.team, this.type);
        }
      }
      
      // Normalize movement to current speed limit
      let speedVal = Math.hypot(this.vx, this.vz);
      if (speedVal > this.speed) {
        this.vx = (this.vx / speedVal) * this.speed;
        this.vz = (this.vz / speedVal) * this.speed;
      }
      this.x += this.vx;
      this.z += this.vz;
      this.x = Math.max(this.radius, Math.min(canvasWidth - this.radius, this.x));
      this.z = Math.max(this.radius, Math.min(canvasHeight - this.radius, this.z));
      
      // Update instance matrix for this unit
      this.updateMatrix();
    }
    
    // When a unit dies, simply move it offscreen
    draw() {
      if (this.health <= 0) {
        dummy.position.set(-10000, -10000, -10000);
        dummy.updateMatrix();
        unitGroups[this.groupKey].mesh.setMatrixAt(this.instanceIndex, dummy.matrix);
      }
    }
  }
  
  // ---------- Projectile Pool & Drawing ----------
  function getProjectileLine() {
    if (projectilePool.length) {
      return projectilePool.pop();
    } else {
      const material = new THREE.LineBasicMaterial({ color: 0xffffff });
      const geometry = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(), new THREE.Vector3()]);
      return new THREE.Line(geometry, material);
    }
  }
  
  function drawProjectile(startX, startZ, endX, endZ, team, type) {
    const line = getProjectileLine();
    // Set color based on team and type
    line.material.color.setHex(team === 'red' ? (type === 'siege' ? 0xff9999 : 0xff6666)
                                             : (type === 'siege' ? 0x99bbff : 0x66a3ff));
    const points = [new THREE.Vector3(startX, 10, startZ), new THREE.Vector3(endX, 10, endZ)];
    line.geometry.setFromPoints(points);
    scene.add(line);
    setTimeout(() => {
      scene.remove(line);
      projectilePool.push(line);
    }, 100);
  }
  
  // ---------- TERRAIN INITIALIZATION ----------
  function initializeTerrain() {
    terrain = [
      new Terrain(300, 200, 'hill'),
      new Terrain(900, 600, 'hill'),
      new Terrain(500, 400, 'forest'),
      new Terrain(700, 200, 'forest'),
      new Terrain(400, 600, 'water'),
      new Terrain(800, 400, 'water')
    ];
  }
  
  // ---------- ARMY ADDITION FUNCTIONS ----------
  function addBlueArmy(type) {
    const count = type === 'siege' ? 3 : type === 'cavalry' ? 6 : type === 'archer' ? 8 : 12;
    for (let i = 0; i < count; i++) {
      const x = canvasWidth - 100 + Math.random() * 50;
      const z = Math.random() * canvasHeight;
      units.push(new Unit('blue', type, x, z));
    }
    updateFormations();
  }
  
  function addRedArmy(type) {
    const count = type === 'siege' ? 3 : type === 'cavalry' ? 6 : type === 'archer' ? 8 : 12;
    for (let i = 0; i < count; i++) {
      const x = 50 + Math.random() * 50;
      const z = Math.random() * canvasHeight;
      units.push(new Unit('red', type, x, z));
    }
    updateFormations();
  }
  
  // ---------- CAMERA CONTROL FUNCTIONS ----------
  function setCameraMode(mode) {
    cameraMode = mode;
    document.querySelectorAll('.mode-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelector(`[onclick="setCameraMode('${mode}')"]`).classList.add('active');
    
    if (mode === 'spectator' && units.length > 0) {
      targetUnit = units[Math.floor(Math.random() * units.length)];
    }
    
    if (mode === 'eagle') {
      camera.position.set(canvasWidth/2, cameraDistance, canvasHeight/2);
      camera.lookAt(new THREE.Vector3(canvasWidth/2, 0, canvasHeight/2));
    }
  }
  
  function zoomCamera(delta) {
    if (cameraMode === 'eagle') {
      cameraDistance = Math.max(MIN_DISTANCE, Math.min(MAX_DISTANCE, cameraDistance + delta));
      camera.position.y = cameraDistance;
    }
  }
  
  function moveCamera(dx, dz) {
    if (cameraMode === 'free' || cameraMode === 'eagle') {
      camera.position.x = Math.max(0, Math.min(canvasWidth, camera.position.x + dx));
      camera.position.z = Math.max(0, Math.min(canvasHeight, camera.position.z + dz));
      if (cameraMode === 'eagle') {
        camera.lookAt(new THREE.Vector3(camera.position.x, 0, camera.position.z));
      }
    }
  }
  
  // ---------- CONTROL TOGGLES ----------
  function toggleFormation() {
    formationActive = !formationActive;
    updateFormations();
  }
  
  function toggleInfiniteSpawn() {
    infiniteSpawn = !infiniteSpawn;
    document.querySelectorAll('.control-btn')[1].textContent = 
      `Auto-Spawn: ${infiniteSpawn ? 'ON' : 'OFF'}`;
  }
  
  function toggleTactics() {
    advancedTacticsEnabled = !advancedTacticsEnabled;
    document.querySelectorAll('.control-btn')[2].textContent = 
      `Advanced Tactics: ${advancedTacticsEnabled ? 'ON' : 'OFF'}`;
  }
  
  // ---------- FORMATION UPDATE ----------
  function updateFormations() {
    if (!formationActive) {
      units.forEach(unit => unit.inFormation = false);
      return;
    }
    const blueUnits = {
      infantry: units.filter(u => u.team === 'blue' && u.type === 'infantry' && u.health > 0),
      archer: units.filter(u => u.team === 'blue' && u.type === 'archer' && u.health > 0),
      cavalry: units.filter(u => u.team === 'blue' && u.type === 'cavalry' && u.health > 0),
      siege: units.filter(u => u.team === 'blue' && u.type === 'siege' && u.health > 0)
    };
    const redUnits = {
      infantry: units.filter(u => u.team === 'red' && u.type === 'infantry' && u.health > 0),
      archer: units.filter(u => u.team === 'red' && u.type === 'archer' && u.health > 0),
      cavalry: units.filter(u => u.team === 'red' && u.type === 'cavalry' && u.health > 0),
      siege: units.filter(u => u.team === 'red' && u.type === 'siege' && u.health > 0)
    };
    
    function setFormation(unitsArr, startX, startZ, rows, cols, spacing) {
      unitsArr.forEach((unit, index) => {
        const row = Math.floor(index / cols);
        const col = index % cols;
        unit.targetX = startX + col * spacing;
        unit.targetZ = startZ + row * spacing;
        unit.inFormation = true;
      });
    }
    
    setFormation(blueUnits.infantry, canvasWidth - 250, canvasHeight/2 - 100, 4, 5, 30);
    setFormation(blueUnits.archer, canvasWidth - 150, canvasHeight/2 - 80, 3, 4, 35);
    setFormation(blueUnits.cavalry, canvasWidth - 200, canvasHeight/2 + 50, 2, 4, 40);
    setFormation(blueUnits.siege, canvasWidth - 100, canvasHeight/2 - 30, 1, 3, 45);
    
    setFormation(redUnits.infantry, 150, canvasHeight/2 - 100, 4, 5, 30);
    setFormation(redUnits.archer, 50, canvasHeight/2 - 80, 3, 4, 35);
    setFormation(redUnits.cavalry, 100, canvasHeight/2 + 50, 2, 4, 40);
    setFormation(redUnits.siege, 200, canvasHeight/2 - 30, 1, 3, 45);
  }
  
  // ---------- RESET FUNCTION ----------
  function resetBattlefield() {
    // Reset the instanced-mesh counts by simply zeroing out each group.
    for (let key in unitGroups) {
      unitGroups[key].count = 0;
    }
    units = [];
    formationActive = false;
    infiniteSpawn = false;
    advancedTacticsEnabled = false;
    battleStartTime = Date.now();
    document.querySelectorAll('.control-btn')[1].textContent = 'Auto-Spawn: OFF';
    document.querySelectorAll('.control-btn')[2].textContent = 'Advanced Tactics: OFF';
  }
  
  // ---------- STATS UPDATE ----------
  function updateStats() {
    const blueStats = units.filter(u => u.team === 'blue' && u.health > 0)
      .reduce((acc, u) => { acc[u.type] = (acc[u.type] || 0) + 1; return acc; }, {});
    const redStats = units.filter(u => u.team === 'red' && u.health > 0)
      .reduce((acc, u) => { acc[u.type] = (acc[u.type] || 0) + 1; return acc; }, {});
    
    document.getElementById('blueCount').textContent =
      `Infantry: ${blueStats.infantry || 0}, Archers: ${blueStats.archer || 0}, Cavalry: ${blueStats.cavalry || 0}, Siege: ${blueStats.siege || 0}`;
    document.getElementById('redCount').textContent =
      `Infantry: ${redStats.infantry || 0}, Archers: ${redStats.archer || 0}, Cavalry: ${redStats.cavalry || 0}, Siege: ${redStats.siege || 0}`;
    
    const battleTime = Math.floor((Date.now() - battleStartTime) / 1000);
    const minutes = Math.floor(battleTime / 60);
    const seconds = battleTime % 60;
    document.getElementById('battleTime').textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }
  
  // ---------- MAIN GAME LOOP ----------
  function gameLoop(time) {
    const deltaTime = clock.getDelta();
    
    if (infiniteSpawn && time - lastSpawnTime > 3000) {
      const types = ['infantry', 'archer', 'cavalry', 'siege'];
      const randomType = types[Math.floor(Math.random() * types.length)];
      addBlueArmy(randomType);
      addRedArmy(randomType);
      lastSpawnTime = time;
    }
    
    const blueTeam = units.filter(u => u.team === 'blue' && u.health > 0);
    const redTeam = units.filter(u => u.team === 'red' && u.health > 0);
    
    blueTeam.forEach(unit => unit.update(blueTeam, redTeam, terrain, time));
    redTeam.forEach(unit => unit.update(redTeam, blueTeam, terrain, time));
    
    // Remove dead units (their instance matrices have been set offscreen)
    units = units.filter(unit => unit.health > 0);
    units.forEach(unit => unit.draw());
    
    // Mark all instanced meshes as needing an update
    for (let key in unitGroups) {
      if (unitGroups[key].mesh) {
        unitGroups[key].mesh.instanceMatrix.needsUpdate = true;
      }
    }
    
    if (cameraMode === 'spectator' && targetUnit && targetUnit.health > 0) {
      const height = 50;
      const distance = 100;
      camera.position.set(
        targetUnit.x - Math.sin(cameraRotation) * distance,
        height,
        targetUnit.z - Math.cos(cameraRotation) * distance
      );
      camera.lookAt(new THREE.Vector3(targetUnit.x, height/2, targetUnit.z));
    }
    
    updateStats();
    renderer.render(scene, camera);
    requestAnimationFrame(gameLoop);
  }
  
  // ---------- EVENT LISTENERS ----------
  // Camera control buttons
  document.getElementById('zoom-in').addEventListener('click', () => zoomCamera(-100));
  document.getElementById('zoom-out').addEventListener('click', () => zoomCamera(100));
  document.getElementById('move-up').addEventListener('click', () => moveCamera(0, -50));
  document.getElementById('move-down').addEventListener('click', () => moveCamera(0, 50));
  document.getElementById('move-left').addEventListener('click', () => moveCamera(-50, 0));
  document.getElementById('move-right').addEventListener('click', () => moveCamera(50, 0));
  
  // Touch events for free camera mode
  let touchStartX = 0, touchStartY = 0;
  document.addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
  });
  document.addEventListener('touchmove', (e) => {
    if (cameraMode === 'free') {
      const touchX = e.touches[0].clientX;
      const touchY = e.touches[0].clientY;
      const deltaX = (touchX - touchStartX) * 0.5;
      const deltaY = (touchY - touchStartY) * 0.5;
      moveCamera(-deltaX, -deltaY);
      touchStartX = touchX;
      touchStartY = touchY;
    }
  });
  
  // Keyboard controls
  document.addEventListener('keydown', (e) => {
    switch(e.key) {
      case 'ArrowUp': moveCamera(0, -50); break;
      case 'ArrowDown': moveCamera(0, 50); break;
      case 'ArrowLeft': moveCamera(-50, 0); break;
      case 'ArrowRight': moveCamera(50, 0); break;
      case '+':
      case '=': zoomCamera(-100); break;
      case '-': zoomCamera(100); break;
      case 'r':
        if (cameraMode === 'spectator' && units.length > 0) {
          targetUnit = units[Math.floor(Math.random() * units.length)];
        }
        break;
    }
  });
  
  // Mouse wheel for zooming
  document.addEventListener('wheel', (e) => { zoomCamera(e.deltaY); });
  
  // Resize handler
  window.addEventListener('resize', () => {
    camera.aspect = window.innerWidth/window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });
  
  // ---------- INITIALIZATION ----------
  initThree();
  initializeTerrain();
  requestAnimationFrame(gameLoop);
  </script>
</body>
</html>