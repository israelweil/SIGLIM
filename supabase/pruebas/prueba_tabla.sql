\set ON_ERROR_STOP 1
-- Datos directos (sin triggers) para probar desempates de calcular_tabla
SET session_replication_role = replica;
INSERT INTO siglim.jornadas (id, grupo_id, numero) VALUES ('a1000000-0000-4000-8000-000000000002', '52000000-0000-4000-8000-000000000001', 1);
INSERT INTO siglim.equipos (id, club_id, grupo_id, nombre) VALUES
 ('61000000-0000-4000-8000-000000000001','c0000000-0000-4000-8000-00000000000a','52000000-0000-4000-8000-000000000001','Zeta'),
 ('61000000-0000-4000-8000-000000000002','c0000000-0000-4000-8000-00000000000b','52000000-0000-4000-8000-000000000001','Alfa'),
 ('61000000-0000-4000-8000-000000000003','c0000000-0000-4000-8000-00000000000c','52000000-0000-4000-8000-000000000001','Beta');
INSERT INTO siglim.partidos (id, jornada_id, equipo_local_id, equipo_visitante_id, cancha_id, inicio, fin_bloque, estado) VALUES
 ('a3000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000002','61000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000002','70000000-0000-4000-8000-000000000001','2026-10-01 09:00-06','2026-10-01 11:00-06','FINALIZADO'),
 ('a3000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000002','61000000-0000-4000-8000-000000000002','61000000-0000-4000-8000-000000000003','70000000-0000-4000-8000-000000000001','2026-10-02 09:00-06','2026-10-02 11:00-06','FINALIZADO'),
 ('a3000000-0000-4000-8000-000000000003','a1000000-0000-4000-8000-000000000002','61000000-0000-4000-8000-000000000003','61000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','2026-10-03 09:00-06','2026-10-03 11:00-06','FINALIZADO');
INSERT INTO siglim.resultados (partido_id, version, goles_local, goles_visitante, origen, resolucion_id, motivo) VALUES
 ('a3000000-0000-4000-8000-000000000001',1,1,0,'RESOLUCION','c3000000-0000-4000-8000-000000000001','prueba'),
 ('a3000000-0000-4000-8000-000000000002',1,1,0,'RESOLUCION','c3000000-0000-4000-8000-000000000001','prueba'),
 ('a3000000-0000-4000-8000-000000000003',1,1,0,'RESOLUCION','c3000000-0000-4000-8000-000000000001','prueba');
SET session_replication_role = origin;
SELECT prueba.verifica((SELECT count(*) FROM siglim.calcular_tabla('52000000-0000-4000-8000-000000000001') WHERE posicion = 1) = 3,
  'DEC-27: triple empate total (también en enfrentamiento directo) comparte la posición 1');
INSERT INTO siglim.sorteos_desempate (grupo_id, equipo_id, orden, registrado_por) VALUES
 ('52000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000003',1,'30000000-0000-4000-8000-000000000001'),
 ('52000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000001',2,'30000000-0000-4000-8000-000000000001'),
 ('52000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000002',3,'30000000-0000-4000-8000-000000000001');
SELECT prueba.verifica((SELECT string_agg(equipo, ',' ORDER BY posicion) FROM siglim.calcular_tabla('52000000-0000-4000-8000-000000000001') WHERE puntos = 3)
  = 'Beta,Zeta,Alfa', 'DEC-27: el sorteo registrado decide el triple empate');
-- Enfrentamiento directo: Beta y Alfa empatan 1-1 en un cuarto partido → Alfa y Beta 4 pts, DG 0, GF 2;
-- entre ellos Alfa ganó 1-0 y empataron 1-1 → Alfa queda arriba por enfrentamiento directo.
SET session_replication_role = replica;
INSERT INTO siglim.partidos (id, jornada_id, equipo_local_id, equipo_visitante_id, cancha_id, inicio, fin_bloque, estado) VALUES
 ('a3000000-0000-4000-8000-000000000004','a1000000-0000-4000-8000-000000000002','61000000-0000-4000-8000-000000000003','61000000-0000-4000-8000-000000000002','70000000-0000-4000-8000-000000000001','2026-10-04 09:00-06','2026-10-04 11:00-06','FINALIZADO');
INSERT INTO siglim.resultados (partido_id, version, goles_local, goles_visitante, origen, resolucion_id, motivo) VALUES
 ('a3000000-0000-4000-8000-000000000004',1,1,1,'RESOLUCION','c3000000-0000-4000-8000-000000000001','prueba');
SET session_replication_role = origin;
DELETE FROM siglim.sorteos_desempate;
SELECT prueba.verifica((SELECT string_agg(equipo || ':' || posicion, ',' ORDER BY posicion, equipo)
                        FROM siglim.calcular_tabla('52000000-0000-4000-8000-000000000001'))
  = 'Alfa:1,Beta:2,Zeta:3,Atlético A Primera:4', 'DEC-27: el enfrentamiento directo separa a Alfa y Beta');
SELECT posicion, equipo, pj, puntos, dg, gf FROM siglim.calcular_tabla('52000000-0000-4000-8000-000000000001');
