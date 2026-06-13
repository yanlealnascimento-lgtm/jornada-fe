import { Request, Response, NextFunction } from 'express';
import { UserModel } from '../../users/user.model';
import { StudyGroupModel } from '../study-group.model';
import { CompanyModel } from '../company.model';
import { sendSuccess, sendError } from '../../../shared/utils/response.util';
import bcrypt from 'bcryptjs';

export class CompanyB2BController {
  
  getMembers = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const companyId = req.user?.company_id;
      if (!companyId) return sendError(res, 'Sua conta não possui instituição vinculada.', 'BAD_REQUEST', 400);

      const users = await UserModel.find({ company_id: companyId }).sort({ level: -1 });
      return sendSuccess(res, users, 'Membros da instituição recuperados.');
    } catch (error) { next(error); }
  };

  getGroups = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const companyId = req.user?.company_id;
      if (!companyId) return sendError(res, 'Obrigatório ID de instituição.', 'BAD_REQUEST', 400);

      const groups = await StudyGroupModel.find({ company_id: companyId }).populate('leader_id');
      return sendSuccess(res, groups, 'Grupos de estudo recuperados.');
    } catch (error) { next(error); }
  };

  // Seed específico para B2B e testes (IBBI)
  seedB2BData = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { slug } = req.body; 
      // Busca flexível: pode ser pelo slug exato ou por parte do nome
      const company = await CompanyModel.findOne({ 
        $or: [
          { slug: slug },
          { name: new RegExp(slug.replace(/-/g, ' '), 'i') }
        ]
      });
      if (!company) return sendError(res, `Instituição "${slug}" não encontrada. Verifique o nome/slug no Admin.`, 'NOT_FOUND', 404);

      const companyId = company._id;
      
      // 1. Criar o Pastor (Admin B2B) se não existir
      const pass = await bcrypt.hash('123456', 10);
      const boss = await UserModel.findOneAndUpdate(
        { email: company.responsible.email },
        { 
          name: company.responsible.name,
          username: company.responsible.name.toLowerCase().replace(/\s+/g, '.'),
          email: company.responsible.email,
          passwordHash: pass,
          role: 'company_admin',
          company_id: companyId,
          is_active: true
        },
        { upsert: true, new: true }
      );

      // 2. Criar 10 membros dummy
      const firstNames = ['Matheus', 'Sara', 'Eunice', 'Lucas', 'João', 'Maria', 'Pedro', 'Marta', 'Tiago', 'Lídia'];
      const results = { members: 0, groups: 0 };

      for (const name of firstNames) {
        try {
          const email = `${name.toLowerCase()}@ibbi.com.br`;
          await UserModel.create({
            name: `${name} Santos`,
            username: `${name.toLowerCase()}.${Math.floor(Math.random() * 1000)}`,
            email,
            passwordHash: pass,
            role: 'user',
            company_id: companyId,
            level: Math.floor(Math.random() * 20) + 1,
            pf_total: Math.floor(Math.random() * 5000),
            streak_current: Math.floor(Math.random() * 15),
            is_active: true
          });
          results.members++;
        } catch (e) { /* ignore duplicates */ }
      }

      // 3. Criar 2 Grupos de Estudo
      const groupA = await StudyGroupModel.create({
        name: 'Ministério de Jovens Transformados',
        description: 'Encontros semanais de estudo e comunhão para jovens de 18-35 anos.',
        category: 'youth',
        company_id: companyId,
        leader_id: boss._id,
        icon_emoji: '🔥'
      });
      
      const groupB = await StudyGroupModel.create({
        name: 'Base Kids - Herdeiros do Reino',
        description: 'Ensino lúdico e gamificado para crianças de 7-12 anos.',
        category: 'kids',
        company_id: companyId,
        leader_id: boss._id,
        icon_emoji: '🎨'
      });
      results.groups = 2;

      return sendSuccess(res, { company: company.name, results }, 'Seed de instituição finalizado.');
    } catch (error) { next(error); }
  };

  createGroup = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const companyId = req.user?.company_id;
      const groupData = { ...req.body, company_id: companyId };
      const group = await StudyGroupModel.create(groupData);
      return sendSuccess(res, group, 'Grupo criado com sucesso.', 201);
    } catch (error) { next(error); }
  };

  updateGroup = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const group = await StudyGroupModel.findOneAndUpdate(
        { _id: id, company_id: req.user?.company_id },
        req.body,
        { new: true }
      );
      if (!group) return sendError(res, 'Grupo não encontrado.', 'NOT_FOUND', 404);
      return sendSuccess(res, group, 'Grupo atualizado com sucesso.');
    } catch (error) { next(error); }
  };

  deleteGroup = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const group = await StudyGroupModel.findOneAndDelete({ _id: id, company_id: req.user?.company_id });
      if (!group) return sendError(res, 'Grupo não encontrado.', 'NOT_FOUND', 404);
      return sendSuccess(res, null, 'Grupo removido com sucesso.');
    } catch (error) { next(error); }
  };

  getSettings = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const companyId = req.user?.company_id;
      const company = await CompanyModel.findById(companyId);
      if (!company) return sendError(res, 'Instituição não encontrada.', 'NOT_FOUND', 404);
      return sendSuccess(res, company, 'Configurações recuperadas.');
    } catch (error) { next(error); }
  };
}
