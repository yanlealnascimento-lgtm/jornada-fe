import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { UserModel } from '../users/user.model';
import { sendSuccess, sendError } from '../../shared/utils/response.util';

/** Gera username a partir do email (parte antes do @) + sufixo aleatório se necessário */
async function generateUsername(email: string, name: string): Promise<string> {
  const base = email.split('@')[0].replace(/[^a-zA-Z0-9_]/g, '_').toLowerCase();
  let username = base;
  let attempts = 0;
  while (await UserModel.findOne({ username })) {
    attempts++;
    username = `${base}_${Math.floor(Math.random() * 9000 + 1000)}`;
    if (attempts > 10) {
      username = `${base}_${Date.now()}`;
      break;
    }
  }
  return username;
}

/** Monta objeto de usuário completo para resposta ao Flutter */
function formatUserResponse(user: any) {
  return {
    id: user._id,
    name: user.name,
    username: user.username,
    email: user.email,
    phone: user.phone ?? null,
    avatar_url: user.avatar_url ?? null,
    role: user.role,
    streak_current: user.streak_current ?? 0,
    streak_best: user.streak_longest ?? 0,
    pf_total: user.pf_total ?? 0,
    pf_to_next_level: user.pf_to_next_level ?? 100,
    pf_weekly: user.pf_weekly ?? 0,
    level: user.level ?? 1,
    energy: user.energy ?? 20,
    manas: user.manas ?? 200,
    denomination: user.denomination,
    daily_goal_minutes: user.daily_goal_minutes ?? 10,
    league_tier: user.league_tier ?? 'bronze',
    league_rank: 0,
    company_id: user.company_id,
  };
}

export class AuthController {
  register = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { name, email, password, denomination, daily_goal_minutes } = req.body;

      if (!name || !email || !password) {
        return sendError(res, 'Nome, e-mail e senha são obrigatórios.', 'VALIDATION_ERROR', 422);
      }
      if (password.length < 6) {
        return sendError(res, 'A senha deve ter pelo menos 6 caracteres.', 'VALIDATION_ERROR', 422);
      }

      const existing = await UserModel.findOne({ email });
      if (existing) {
        return sendError(res, 'E-mail já cadastrado.', 'CONFLICT', 409);
      }

      const username = await generateUsername(email, name);
      const passwordHash = await bcrypt.hash(password, 10);
      const user = await UserModel.create({
        name,
        username,
        email,
        passwordHash,
        denomination: denomination ?? 'evangelical',
        daily_goal_minutes: daily_goal_minutes ?? 10,
        role: 'user',
      });

      const token = jwt.sign(
        { userId: user._id.toString(), email: user.email, role: user.role },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      return sendSuccess(res, {
        token,
        user: formatUserResponse(user),
      }, 'Conta criada com sucesso.', 201);
    } catch (error) { next(error); }
  };

  login = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, password } = req.body;

      const user = await UserModel.findOne({ email }).select('+passwordHash');
      if (!user) {
        return sendError(res, 'Credenciais inválidas.', 'UNAUTHORIZED', 401);
      }

      const isMatch = await bcrypt.compare(password, user.passwordHash);
      if (!isMatch) {
        return sendError(res, 'Credenciais inválidas.', 'UNAUTHORIZED', 401);
      }

      const token = jwt.sign(
        {
          userId: user._id.toString(),
          email: user.email,
          role: user.role,
          company_id: user.company_id?.toString()
        },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      return sendSuccess(res, {
        token,
        user: formatUserResponse(user),
      }, 'Login realizado com sucesso.');
    } catch (error) { next(error); }
  };

  me = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const user = await UserModel.findById(req.user?.userId);
      if (!user) return sendError(res, 'Sessão inválida.', 'UNAUTHORIZED', 401);
      return sendSuccess(res, formatUserResponse(user));
    } catch (error) { next(error); }
  };
}
