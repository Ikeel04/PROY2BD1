# Universidad del Valle de Guatemala
# Base de Datos 1
# Proyecto 2 - Simulación
# Adrián Ricardo González Muralles - 23152

import psycopg2
import sys
from psycopg2 import sql
from psycopg2.extras import execute_values
import threading
import random
import time
from datetime import datetime
import os
import io

os.environ['PYTHONUTF8'] = '1'
os.environ['PGCLIENTENCODING'] = 'UTF-8'
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


class ReservaSimulator:
    def __init__(self, dbname='proyecto2', user='postgres', password='postgres', host='localhost'):
        if isinstance(password, str):
            password = password.encode('latin1').decode('utf-8', errors='replace')
        self.db_config = {
            'dbname': dbname,
            'user': user,
            'password': password,
            'host': host
        }
        self.connection_pool = []
        self.lock = threading.Lock()
        
    def get_connection(self):
        try:
            conn = psycopg2.connect(
                dbname=self.db_config['dbname'],
                user=self.db_config['user'],
                password=self.db_config['password'],
                host=self.db_config['host'],
                client_encoding='UTF8'
            )
            return conn
        except Exception as e:
            print(f"Error de conexión: {str(e)}")
            raise
    
    def reserve_seat(self, user_id, event_id, isolation_level):
        conn = self.get_connection()
        conn.set_isolation_level(isolation_level)
        cursor = conn.cursor()
        
        try:
            # 1. Buscar un asiento disponible aleatorio
            cursor.execute("""
                SELECT asiento_id FROM Asientos 
                WHERE evento_id = %s AND estado = 'disponible'
                ORDER BY random() LIMIT 1 FOR UPDATE;
            """, (event_id,))
            seat = cursor.fetchone()
            
            if not seat:
                print(f"Usuario {user_id}: No hay asientos disponibles")
                return False
            
            seat_id = seat[0]
            
            # 2. Crear la reserva
            reservation_code = f"RES-{user_id}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            cursor.execute("""
                INSERT INTO Reservas (asiento_id, usuario_id, evento_id, codigo_reserva)
                VALUES (%s, %s, %s, %s) RETURNING reserva_id;
            """, (seat_id, user_id, event_id, reservation_code))
            reservation_id = cursor.fetchone()[0]
            
            # 3. Actualizar estado del asiento
            cursor.execute("""
                UPDATE Asientos SET estado = 'reservado' 
                WHERE asiento_id = %s;
            """, (seat_id,))
            
            # 4. Registrar transacción
            cursor.execute("""
                INSERT INTO Transacciones (reserva_id, usuario_id, tipo, detalles)
                VALUES (%s, %s, %s, %s);
            """, (reservation_id, user_id, 'reserva', f'Reserva simulada por usuario {user_id}'))
            
            conn.commit()
            print(f"Usuario {user_id}: Reserva exitosa para asiento {seat_id}")
            return True
            
        except Exception as e:
            conn.rollback()
            print(f"Usuario {user_id}: Error en reserva - {str(e)}")
            return False
        finally:
            cursor.close()
            conn.close()
    
    def simulate_user(self, user_id, event_id, isolation_level, attempts=3):
        for _ in range(attempts):
            if self.reserve_seat(user_id, event_id, isolation_level):
                return
            time.sleep(random.uniform(0.1, 0.5))
        print(f"Usuario {user_id}: No pudo reservar después de {attempts} intentos")
    
    def run_simulation(self, num_users, event_id, isolation_level):
        print(f"\nIniciando simulación con {num_users} usuarios (Nivel: {isolation_level})")
        threads = []
        
        # Obtener estado inicial para reporte
        initial_available = self.get_available_seats(event_id)
        
        # Crear hilos para usuarios
        for i in range(1, num_users + 1):
            t = threading.Thread(
                target=self.simulate_user,
                args=(i, event_id, isolation_level)
            )
            threads.append(t)
            t.start()
            time.sleep(random.uniform(0, 0.1))  # Pequeña variación en el inicio
        
        # Esperar a que todos los hilos terminen
        for t in threads:
            t.join()
        
        # Obtener resultados
        final_available = self.get_available_seats(event_id)
        successful_reservations = self.get_successful_reservations(event_id)
        
        print("\n=== Resultados de la simulación ===")
        print(f"Asientos disponibles iniciales: {initial_available}")
        print(f"Asientos disponibles finales: {final_available}")
        print(f"Reservas exitosas: {successful_reservations}")
        print(f"Conflictos detectados: {initial_available - final_available - successful_reservations}")
    
    def get_available_seats(self, event_id):
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT COUNT(*) FROM Asientos 
            WHERE evento_id = %s AND estado = 'disponible';
        """, (event_id,))
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return count
    
    def get_successful_reservations(self, event_id):
        conn = self.get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT COUNT(*) FROM Reservas 
            WHERE evento_id = %s AND estado = 'activa';
        """, (event_id,))
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return count

if __name__ == "__main__":
    try:
        simulator = ReservaSimulator()
    
        # Configuración de pruebas
        EVENT_ID = 1 
        USER_COUNTS = [5, 10, 20, 30]
        ISOLATION_LEVELS = [
            psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED,
            psycopg2.extensions.ISOLATION_LEVEL_REPEATABLE_READ,
            psycopg2.extensions.ISOLATION_LEVEL_SERIALIZABLE
        ]
    
        # Ejecutar todas las combinaciones de pruebas
        for isolation in ISOLATION_LEVELS:
            for users in USER_COUNTS:
                simulator.run_simulation(users, EVENT_ID, isolation)
                time.sleep(2)
    
    except Exception as e:
        print(f"Error general: {str(e)}")