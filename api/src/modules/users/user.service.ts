import bcrypt from 'bcryptjs';
import { UserRepository } from './user.repository';
import { IUser } from './user.model';

export class UserService {
  private repository: UserRepository;

  constructor() {
    this.repository = new UserRepository();
  }

  async createUser(data: any): Promise<IUser> {
    const existingUser = await this.repository.findByEmail(data.email);
    if (existingUser) {
      // Como a lógica de negócio fica no service, podemos disparar erros 
      // ou retornar resultados customizados que o Controller tratará.
      const error: any = new Error('Usuário com este e-mail já existe.');
      error.statusCode = 409;
      error.code = 'DUPLICATE_EMAIL';
      throw error;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password, salt);

    const userData: Partial<IUser> = {
      email: data.email,
      name: data.name,
      passwordHash,
      role: data.role || 'user',
      company_id: data.company_id,
    };

    const newUser = await this.repository.create(userData);
    // Remover o passwordHash antes de retornar
    newUser.passwordHash = '';
    return newUser;
  }

  async getUserById(id: string): Promise<IUser | null> {
    return await this.repository.findById(id);
  }

  async getAllUsers(): Promise<IUser[]> {
    return await this.repository.findAll();
  }

  async updateUser(id: string, data: Partial<IUser>): Promise<IUser | null> {
    return await this.repository.update(id, data);
  }

  async deleteUser(id: string): Promise<boolean> {
    return await this.repository.delete(id);
  }
}
